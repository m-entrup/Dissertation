// This script will change the value of the tag "EELS:Acquisition:Projection:Read height".
// "Read height" defines the with of the camera that is used to record an EEL Spectrum.

// Michael Entrup, michael.entrup@wwu.de
// version:20160909

number tagValue, newTagValue
string fullTagPath="EELS:Acquisition:Projection:Read height"

// Display the old value
getPersistentNumberNote(fullTagPath,tagValue)
result("The current Read heigt is: " + tagValue + "\n")

// Show a number dialog and change the value
if(getNumber("Enter the new Read height: ", tagValue, newTagValue))
{
	setPersistentNumberNote(fullTagPath, newTagValue)
	// Display the new value
	getPersistentNumberNote(fullTagPath, tagValue)
	result("The new Read height is: " + tagValue + "\n")
}