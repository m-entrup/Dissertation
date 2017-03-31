isSetSliceLabels = false;
# Ein Dialog wird angezeigt, bei dem man Yes, No und Cancel wählen kann:
if ( getBoolean("Include means as slice labels?") ) {
    isSetSliceLabels = true;
}
# Den Titel des gewählten Bildes auslesen:
title = getTitle();
# Nur die Kopie soll verändert werden:
run("Duplicate...", "title=" + title + "-norm duplicate");
# Der Schleifenkörper wird so oft ausgeführt, wie es Slices im Stack gibt:
for (i = 1; i <= nSlices; i++) {
    # Ein Slice des Stacks wird ausgewählt:
    setSlice(i);
    # Es werden verschiedene statistische Daten zum Slice ausgelesen:
    getStatistics(area, mean, min, max, std, histogram);
    # Nur mean wird benutzt, um den Slice pixelweise durch diesen Wert zu dividieren:
    run("Divide...", "value=" + mean + " slice");
    # Wurde es gewünscht, dann wird der alte Mittelwert als Slice-Label angegeben:
    if ( isSetSliceLabels ) {
        run("Set Label...", "label=" + mean);
    }
}
setSlice(1);
# Der dargestellte Wertebereich muss noch angepasst werden:
run("Enhance Contrast", "saturated=0.35");
