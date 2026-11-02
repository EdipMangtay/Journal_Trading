#!/usr/bin/env python3
"""Install the locally built app and pin a single Dock entry without replacing other tiles."""
from pathlib import Path
import argparse
from datetime import datetime
import plistlib
import subprocess
import tempfile
from urllib.parse import unquote, urlparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--no-launch', action='store_true', help='Install and pin; leave launching to the caller.')
options = parser.parse_args()
root = Path(__file__).resolve().parent.parent
source = root / 'build/local/Liquidity Edge.app'
destination = Path.home() / 'Applications/Liquidity Edge.app'
if not (source / 'Contents/MacOS/Liquidity Edge').is_file():
    raise SystemExit('Build the local app first using Scripts/build-local.sh')
destination.parent.mkdir(parents=True, exist_ok=True)
if destination.exists():
    archive_folder = Path.home() / 'Library/Application Support/LiquidityEdge/Installation-Backups'
    archive_folder.mkdir(parents=True, exist_ok=True)
    previous = archive_folder / ('Liquidity Edge.previous-' + datetime.now().strftime('%Y%m%d-%H%M%S') + '.app.zip')
    subprocess.run(['/usr/bin/ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(destination), str(previous)], check=True)
subprocess.run(['/usr/bin/ditto', str(source), str(destination)], check=True)
subprocess.run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(destination)], check=True)
subprocess.run(['/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister', '-f', str(destination)], check=True)
raw = subprocess.check_output(['/usr/bin/defaults', 'export', 'com.apple.dock', '-'])
preferences = plistlib.loads(raw)
tiles = preferences.get('persistent-apps', [])

def journal_tile(tile):
    data = tile.get('tile-data', {})
    path = unquote(urlparse(data.get('file-data', {}).get('_CFURLString', '')).path).rstrip('/')
    return data.get('bundle-identifier') == 'com.liquidityedge.journal' or path == str(destination)

entry = {'tile-data': {'file-data': {'_CFURLString': destination.as_uri() + '/', '_CFURLStringType': 15},
                       'file-label': 'LIQUIDITY EDGE', 'bundle-identifier': 'com.liquidityedge.journal'},
         'tile-type': 'file-tile'}
updated = []
inserted = False
for tile in tiles:
    if journal_tile(tile):
        if not inserted:
            updated.append(entry)
            inserted = True
    else:
        updated.append(tile)
if not inserted:
    updated.append(entry)
if updated != tiles:
    # Keep the original Dock preferences available and preserve every unrelated tile.
    backup_folder = Path.home() / 'Library/Application Support/LiquidityEdge/Installation-Backups'
    backup_folder.mkdir(parents=True, exist_ok=True)
    backup = backup_folder / ('dock-' + datetime.now().strftime('%Y%m%d-%H%M%S') + '.plist')
    backup.write_bytes(raw)
    backup.chmod(0o600)
    preferences['persistent-apps'] = updated
    with tempfile.NamedTemporaryFile(suffix='.plist') as temporary:
        temporary.write(plistlib.dumps(preferences))
        temporary.flush()
        subprocess.run(['/usr/bin/defaults', 'import', 'com.apple.dock', temporary.name], check=True)
    subprocess.run(['/usr/bin/killall', 'Dock'], check=False)
if not options.no_launch:
    subprocess.run(['/usr/bin/open', str(destination)], check=True)
verified = plistlib.loads(subprocess.check_output(['/usr/bin/defaults', 'export', 'com.apple.dock', '-']))
assert any(unquote(urlparse(tile.get('tile-data', {}).get('file-data', {}).get('_CFURLString', '')).path).rstrip('/') == str(destination) for tile in verified.get('persistent-apps', [])), 'Dock entry could not be verified'
print('Installed: ' + str(destination))
print('Dock entry: verified')
print('Launch: ' + ('left to caller' if options.no_launch else 'requested successfully'))
