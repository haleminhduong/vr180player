# VR180 Player

A stereo viewer for side-by-side dual-fisheye photos (VR180), built for a Steam Deck with Rokid Max glasses.

Head tracking comes from [XRLinuxDriver](https://github.com/wheaney/XRLinuxDriver) in its VR-Lite mouse mode.
The driver turns glasses rotation into relative mouse motion. The page captures it with pointer lock and turns it back into yaw and pitch.
Each eye's fisheye circle is reprojected into a perspective view and drawn to its half of the screen, while the glasses run in 3D SBS mode.

## How the head tracking maps

The driver writes `REL_X`/`REL_Y` as angular velocity times `mouse_sensitivity` divided by the IMU rate.
One mouse count is therefore `1 / mouse_sensitivity` degrees, so the viewer needs the same sensitivity value as the driver.
The launcher reads it from `~/.config/xr_driver/config.ini` and passes it as `?sens=`.

## Setup on the Steam Deck

1. Install XRLinuxDriver (or the Decky XR Gaming plugin) and confirm the glasses move the mouse.
2. Make sure the driver is enabled and in mouse mode: `xr_driver_cli -e --use-mouse`.
3. Install Google Chrome from Discover.
4. Copy this folder to the Deck and run `deck/vr180player.sh`. Add it as a non-Steam game to use it from Game Mode.
5. Click **Open images**, pick photos, then **Start**. Press Space to recenter while looking straight ahead.

The launcher writes `sbs_mode=enable` to `/dev/shm/xr_driver_control`, which switches the Rokid glasses to 3840x1200 3D mode.
It switches back to 2D when the browser closes.

## URL parameters

| Param     | Default | Meaning |
|-----------|---------|---------|
| `sens`    | 30      | Driver `mouse_sensitivity` (counts per degree) |
| `fov`     | 46      | Horizontal field of view per eye, in degrees |
| `fishfov` | 180     | Lens field of view |
| `circle`  | 1.0     | Fisheye circle diameter relative to the half-image height |
| `swap`    | 0       | `1` swaps eyes, needed for Canon RF 5.2mm dual fisheye originals |
| `sbs`     | 1       | `0` renders a single 2D view |
| `invx`, `invy` | 0  | `1` inverts an axis |
| `hud`     | 1       | `0` hides the info line |
| `src`     |         | Image URL to open on start |

Pass extra parameters through the launcher with `VR180_ARGS="swap=1&fov=50" deck/vr180player.sh`.

## Testing on a desktop

```
python3 -m http.server 8180
```

Open `http://localhost:8180/?sbs=0`, load an image, click Start and move the mouse.

## Known limitations

- **Rokid Max 2 support is unconfirmed.** The driver README lists the Max and Air only. Its Rokid code accepts USB product IDs 162B to 162F, 2002 and 2180. Check `lsusb` for vendor `04d2` and the driver log to see if your Max 2 is detected.
- **Slow drift.** The driver truncates angular velocity to whole degrees per second before scaling it into mouse counts, so very slow head motion is lost. Recenter with Space when the view drifts. Reading the driver's absolute orientation instead would fix this, but that needs a native helper because a browser cannot read shared memory.
- The fisheye model is equidistant (`r = f·θ`). Lenses with a different projection will look slightly warped near the edge.
