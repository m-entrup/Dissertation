## ToDo

- Screenshot des GUI machen und einfügen.

# Scripte für Gatan Digital Micrograph

Für die Aufnahmen zu meiner Dissertation habe ich eine Reihe von Scripten erstellt, welche die Aufnahme von Bildserien automatisieren. Der Aufbau der Scripte ist sehr ähnlich, weshalb nur ``Acquire_ImageSpecSeries.s`` mit detaillierten Kommentaren versehen ist.

Im Folgenden ist erläutert, warum die Scripte geschrieben wurden und wie deren Funktionsprinzip ist.

## Imaging Spectroscopy

Gatan bietet für Digital Micrograph ein Software-Modul an, welches Spectrum Imaging mit ESI, als auch mit STEM-EELS erlaubt. Da wir dieses Modul auf Grund des Fehlens von Digi-Scan nur teilweise nutzen können, wurde bei der Aktualisierung von Digital Micrograph auf eine neue Version keine Lizenz für das Spectrum Imaging Modul erworben. Die Aufzeichnung von Imaging Spectroscopy Datensätzen im ESI-Modus wurde deshalb mit einem selbst geschriebenen Programm realisiert, welches in diesem Abschnitt kurz erläutert werden soll. Das Script trägt die Bezeichnung ``Acquire_ImageSpecSeries.s``.

Die Funktionsweise des selbst geschriebenen Scripts ist kurz erklärt: Der Nutzer wählt die gewünschten Parameter und startet die Messung. Zu jedem Energieverlust wird ein Bild aufgenommen, welches Digital Micrograph anzeigt. Jedes Bild wird einzelne Datei in einem Ordner abgespeichert, den der Nutzer zu Beginn der Messung gewählt hat. Die Bezeichnung der einzelnen Bilddateien enthält alle Parameter, die vom Nutzer festgelegt wurden. Das Dateiformat von Digital Micrograph könnte sämtliche Daten als dreidimensionalen Datensatz abspeichern, jedoch ist der Import dieses Datensatzes mit ImageJ problematisch.

Die Parameter der Messung zeigt Abbildung .... *Acquisition Time (sec)* und *Binning* sind selbsterklärend. *Experiment name* ist ein String, mit dem der Name aller erzeugten Bilddateien beginnt. Damit lassen sich die zu einer Messung gehörenden Dateien einfacher identifizieren. Innerhalb der Kategorie *Image Spec settings* legen die Parameter *Start energy loss (eV)*, *Stop energy loss (eV)* und *Energy loss step (eV)* den Wertebereich der energiedispersiven Achse fest. Beginnend mit dem ersten Energieverlust werden die energieselektiven Bilder aufgenommen. Die Schrittweite darf auch negativ sein, so lange auch der Startwert größer als dar Endwert ist. Abhängig von der Schrittweite kann es passieren, dass der Endwert nicht verwendet wird (zum Beispiel bei 100eV bis 125eV mit 2eV Schrittweite).


## Weitere Scripte

Neben dem Script zur Aufnahme von Imaging Spectroscopy Bildserien wurden weitere Scripte entwickelt. Dazu zählt ein Script zur Aufnahme von Bildserien zur Kalibrierung von EELS mit der in Anhang D beschriebenen Methode. Dort ist das entsprechende Script (``Acquire_EELSCalSeries.s``) kurz beschrieben. 

Ein weiteres Script (``Acquire\_SingleImage.s``) nimmt nur ein einzelnes Bild auf, jedoch kann das Binning für jede Achse einzeln eingestellt werden. Die an Abschnitt 3.2 gezeigten SR-EELS Messungen verwenden diese Methode. 

Zwei weitere Scripte finden in meiner Dissertation keine Verwendung, da sie auf dem Code von ``Acquire_ImageSpecSeries.s`` basieren, sind sie über dieses GitHub-Repository verfügbar. ``Acquire_FocusSeries.s`` variiert statt dem Energieverlust den Focus der Objektivlinse. Dadurch lassen sich Defokus-Reihen aufnehmen, mit denen man die Kontrastübertragungsfunktion der Objektivlinse ermitteln kann. Die in dem Script eingestellten Werte stimmen nicht exakt mit den vom Zeiss Libra 200FE verwendeten Werten überein. Für eine quantitative Auswertung ist eine Kalibrierung notwendig.

Zuletzt ist noch ``Acquire_ExposureSeries.s`` zu nennen. Mit diesem Script lässt sich die Belichtungszeit variieren. Damit lässt sich überprüfen, ob die mit der Kamera gemessene Intensität linear mit der Belichtungszeit steigt. Auf diese Weise konnten die minimalen Belichtungszeiten für die verschiedenen Shutter des Mikroskops bestimmt werden. Das Zeiss Libra 200FE besitzt 8 verschiedene Shutter, welche die Belichtung der Kamera steuern können. Abhängig von Funktionsweise und Position der Shutter ergeben sich unterschiedliche minimale Belichtungszeiten. Die Auswertung der mit ``Acquire_ExposureSeries.s`` aufgenommenen Bilder zeigt das Juyter-Notebook [``Acquire_ExposureSeries.s``][exp-Auswertung].

[exp-Auswertung]: https://github.com/m-entrup/Dissertation/blob/master/Jupyter-Notebooks/Sonstiges/Shutter.ipynb
