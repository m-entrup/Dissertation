String title = "Acquire Single Image";
String version = "0.2.0";
String date = "February 2017";
String author = "M. Entrup";

/*
 * All acquire scripts use a similar structure.
 * Therefoe only Acquire_EELSCalSeries.s contains extensive comments.
 */


TagGroup createRealField(string identifier, string description, number value) {
        TagGroup field = DLGIdentifier(DLGCreateRealField(value), identifier);
        TagGroup label = DLGCreateLabel(description);
        TagGroup input = DLGGroupItems(label, field);
        return input;
}


TagGroup createIntegerField(string identifier, string description, number value) {
        TagGroup field = DLGIdentifier(DLGCreateIntegerField(value), identifier);
        TagGroup label = DLGCreateLabel(description);
        TagGroup input = DLGGroupItems(label, field);
        return input;
}


class SimpleAcquisitionDialog: uiframe {


        number acquisitionTime;
        number binX;
        number binY;


        void RecordImage(object self) {
                object ImageAcqPara, CCDCamera; //Objects needed for the CM functions
                number CCDWidth, CCDHeight;
                image AcquiredImage;
                number ImageProcessing = 3; //1 - No dark or gain correction, 2 - Dark correction only, 3 - Dark and gain correction.
                SSCGetSize(CCDWidth, CCDHeight);
                CCDcamera = CM_GetCurrentCamera();
                ImageAcqPara = CM_GetCameraAcquisitionParameterSet_HighQualityImagingAcquire(CCDcamera);
                CM_SetExposure(ImageAcqPara, acquisitionTime);
                CM_SetBinning(ImageAcqPara, binX, binY);
                CM_SetProcessing(ImageAcqPara, ImageProcessing);
                CM_SetCCDReadArea(ImageAcqPara, 0, 0, CCDWidth, CCDHeight);
                CM_SetAcqTranspose(ImageAcqPara, CM_Config_GetDefaultTranspose(CCDcamera));
                //  SSCClear()  // Does not play well with continuous view acquisition active
                AcquiredImage = CM_CreateImageForAcquire(CCDcamera, ImageAcqPara, "Record");
                CM_AcquireImage(CCDcamera, ImageAcqPara, AcquiredImage);
                fliphorizontal(AcquiredImage);
                ShowImage(AcquiredImage);
                imagedisplay imgdisp = getfrontimage().imagegetimagedisplay(0);
                if (imgdisp.componentcountchildrenoftype(31) <= 0) {
                        number fontsize = 60;
                        number fontstyle = 12;                  // 0 for regular, 12 for bold, 22 for italic
                        imgdisp.applydatabar(0);
                        component scalebar = imgdisp.componentgetnthchildoftype(31, 0);
                        scalebar.componentsetfontinfo("Times New Roman", fontstyle, fontsize);
                        scalebar.componentsetdrawingmode(1);
                }
        }


        void ButtonResponse(object self) {
                DLGGetValue(self, "AcqTime", acquisitionTime);
                DLGGetValue(self, "BinX", binX);
                DLGGetValue(self, "BinY", binY);
                self.RecordImage();
        }


        TagGroup MakeButton(object self){
                // Creates a box in the dialog which surrounds the button
                TagGroup box_items;
                TagGroup box = DLGCreateBox("Record Image", box_items);
                box.DLGExternalPadding(5, 5);
                box.DLGInternalPadding(50, 5);
                // Creates the first button
                TagGroup firstButton = DLGCreatePushButton("Record", "ButtonResponse");
                DLGEnabled(firstButton, 1); // sets the button as enabled when the dialog is first created
                DLGIdentifier(firstButton, "first"); // identifiers are strings which identify an element, such as a button
                // they are used to change the enabled/disabled status of the element in the button response functions above
                firstbutton.DLGInternalPadding(10, 0);
                box_items.DLGAddElement(firstButton);
                return box;
        }
        
        
        TagGroup MakeSettings(object self){
				TagGroup box_items;
                TagGroup box = DLGCreateBox("Settings", box_items);
                box.DLGExternalPadding(5, 5);
                box.DLGInternalPadding(5, 5);
                box.DLGAddElement(createRealField("AcqTime", "Acquisition Time (sec)", 1));
                box.DLGAddElement(createIntegerField("BinX", "Binning (x-axis)", 1));
                box.DLGAddElement(createIntegerField("BinY", "Binning (y-axis)", 1));
                return box;
        }


        TagGroup createDialog(object self){
                // This function creates the dialog, drawing togther the parts (buttons etc) which make it up
                // and alloc 'ing' the dialog with the response, so that one responds to the other. It also
                // displays the dialog
                // Configure the positioning in the top right of the application window
                TagGroup position;
                position = DLGBuildPositionFromApplication();
                position.TagGroupSetTagAsTagGroup("Width", DLGBuildAutoSize());
                position.TagGroupSetTagAsTagGroup("Height", DLGBuildAutoSize());
                position.TagGroupSetTagAsTagGroup("X", DLGBuildRelativePosition("Inside", 1));
                position.TagGroupSetTagAsTagGroup("Y", DLGBuildRelativePosition("Inside", 1));
                TagGroup dialog_items;
                TagGroup dialog = DLGCreateDialog("Acquire Image", dialog_items);
                dialog.DLGPosition(position);
                dialog_items.DLGAddElement(self.MakeSettings());
                dialog_items.DLGAddElement(self.MakeButton());
                dialog_items.DLGAddElement(DLGCreateLabel(author + ", v." + version + " (" + date + ")"));
                return dialog;
        }


        SimpleAcquisitionDialog(object self) {
                self.super.init(self.createDialog());
                self.display(title);
        }


}


// Creates the above dialog
alloc(SimpleAcquisitionDialog)
