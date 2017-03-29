dir = getDirectory(
    "Choose the directory \"20151027 Schritt für Schritt zu SR-EELS/4. Von EELS nach SR-EELS/\""
)
open(dir + "EELS 0eV SM200 mit 100µm Blende 0,05s.dm3");
disp = 0.030217566
run("Properties...", "channels=1 slices=1 frames=1 unit=eV pixel_width="+disp+" pixel_height="+disp+" voxel_depth=1.0");
run("Rotate 90 Degrees Left");
makeRectangle(1912, 2080, 4096 - 1912, 256);
profile = getProfile();
maxLocs = Array.findMaxima(profile, 10);
offset = maxLocs[0];
toScaled(offset)
for (i=0; i<profile.length; i++) {
    eLoss = i;
    toScaled(eLoss);
    setResult("ELoss", i, eLoss - offset);
    setResult("Intensity", i, profile[i]);
}
run("Rotate 90 Degrees Right");
run("Bin...", "x=4 y=4 bin=Average");
makeRectangle(1024 - 520 - 64, 478, 64, 1024 - 478);
setMinAndMax(0, 300);

run("Overlay Options...", "stroke=green width=8 set");
run("Add Selection...");
run("Select None");

run("Flatten");
setFont("SansSerif", 36, "bold");
run("Arrow Tool...", "width=5 size=36 color=White style=Notched");
setColor(255, 255, 255);
setForegroundColor(255, 255, 255);
drawString("Integration", 300, 150)
makeArrow(300, 250, 600, 250, "notched large");
Roi.setStrokeWidth(10);
run("Draw", "slice");
run("Rotate 90 Degrees Right");
drawString("Energiedispersion", 300, 150)
makeArrow(600, 250, 300, 250, "notched large");
Roi.setStrokeWidth(10);
run("Draw", "slice");
run("Rotate 90 Degrees Left");
run("Select None");
saveAs("PNG", dir + "EELS_RAW");

selectWindow("EELS 0eV SM200 mit 100µm Blende 0,05s.dm3");
close();

updateResults;
saveAs("Results", dir + "EELS_RAW.tsv");
