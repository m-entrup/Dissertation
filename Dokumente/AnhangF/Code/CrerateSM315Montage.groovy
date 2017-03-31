import ij.IJ

IJ.run("Close All", "")

def openImages(dir, images) {
	for (image in images) {
		IJ.openImage(dir + image).show()
	}
}

def createProjection() {
	IJ.run(null, "Images to Stack", "name=stack title=[] use")
	stack = IJ.getImage()
	IJ.run(stack, "Remove Outliers...", "radius=3 threshold=10 which=Bright")
	IJ.run(stack, "Remove Outliers...", "radius=3 threshold=10 which=Dark")
	IJ.run(IJ.getImage(), "Z Project...", "projection=[Average Intensity]")
	//IJ.run(IJ.getImage(), "Log", "");
	IJ.run(IJ.getImage(), "Enhance Contrast", "saturated=0.35")
	stack.changes = false
	stack.close()
}

dir = "/run/media/michael/LinuxSSD/SR-EELS Daten/SM315/0/20140507 225eV/"
images = ["Cal_01.tif", "Cal_02.tif", "Cal_04.tif"]
openImages(dir, images)
createProjection()
stack0 = IJ.getImage()
stack0.hide()

dir = "/run/media/michael/LinuxSSD/SR-EELS Daten/SM315/-8/20160303 240eV_QSinK4=-2,5%_SpecRot=0,3%/"
images =["Cal_01.tif", "Cal_02.tif", "Cal_06.tif"]
openImages(dir, images)
createProjection()
stack8 = IJ.getImage()
stack8.hide()

dir = "/run/media/michael/LinuxSSD/SR-EELS Daten/SM315/-12/20150401/"
images = ["Cal_01.tif", "Cal_02.tif", "Cal_03.tif"]
openImages(dir, images)
createProjection()
stack12 = IJ.getImage()


IJ.setMinAndMax(stack0, 0, 2000)
IJ.setMinAndMax(stack8, 0, 100)
IJ.setMinAndMax(stack12, 0, 15)

stack0.show()
stack8.show()
stack12.updateAndDraw()

IJ.run(stack0, "Bin...", "x=2 y=2 bin=Average")
IJ.run(stack8, "Bin...", "x=2 y=2 bin=Average")
IJ.run(stack12, "Bin...", "x=4 y=4 bin=Average")

img0 = stack0.flatten()
img0.setTitle("QSinK7 = 0%")
stack0.close()
img8 = stack8.flatten()
img8.setTitle("SinK7 = -8%")
stack8.close()
img12 = stack12.flatten()
img12.setTitle("QSinK7 = -12%")
stack12.close()

img0.show()
img8.show()
img12.show()
IJ.run(null, "Images to Stack", "name=stack title=[] use")
stack = IJ.getImage()
IJ.run(stack, "Make Montage...", "columns=3 rows=1 scale=1 border=8 font=96 label")
stack.close()
IJ.saveAs(IJ.getImage(), "PNG", "/home/michael/git/Dissertation/LaTeX_main/Bilder/QSinK7_SM315_Montage.png")