String title = "Focus Series";
String version = "0.2.0";
String date = "February 2017";
String author = "M. Entrup";

/*
 * All acquire scripts use a similar structure.
 * Therefoe only Acquire_EELSCalSeries.s contains extensive comments.
 */


class AcquisitionDialog: uiframe {


    Object imageAcqPara, CCDCamera;
    TagGroup btnRecord;
    number binning, exp, focus, f_start, f_stop, f_step;
    string folderSave, experimentName;


    void saveImage(object self, image img) {
        SaveImage(img, folderSave + ImageGetName(img) + ".dm3");
    }


    void setupCamera(object self) {
        number CCDWidth, CCDHeight, imageProcessing;

        // Info on imageProcessing:
        // 1 - No dark or gain correction
        // 2 - Dark correction only
        // 3 - Dark and gain correction
        imageProcessing = 3;

        SSCGetSize(CCDWidth, CCDHeight);
        CCDcamera = CM_GetCurrentCamera();
        imageAcqPara = CM_GetCameraAcquisitionParameterSet_HighQualityImagingAcquire(CCDcamera);
        CM_SetBinning(ImageAcqPara, binning, binning);
        CM_SetProcessing(ImageAcqPara, ImageProcessing);
        CM_SetCCDReadArea(ImageAcqPara, 0, 0, CCDWidth, CCDHeight);
        CM_SetAcqTranspose(ImageAcqPara, CM_Config_GetDefaultTranspose(CCDcamera));
    }


    void recordImage(object self) {
        image acquiredImage;

        CM_SetExposure(ImageAcqPara, exp);
        acquiredImage = CM_CreateImageForAcquire(CCDcamera, ImageAcqPara, "Record");
        string parameters;
        parameters = "_Bin" + binning + "_" + exp + "s_df=" + focus + "nm";
        ImageSetName(acquiredImage, experimentName + parameters);
        CM_AcquireImage(CCDcamera, ImageAcqPara, acquiredImage);
        fliphorizontal(acquiredImage);
        self.saveImage(acquiredImage);
        showImage(acquiredImage);
    }


    void runThread(object self) {
        number n = 1;
        if (GetDirectoryDialog("Select folder to save the image series", folderSave, folderSave)) {
            experimentName = DLGGetStringValue(LookupElement(self, "Experiment name"));
            exp = DLGGetValue(LookupElement(self, "Exposure"));
            binning = DLGGetValue(LookupElement(self, "Binning"));
            f_start = DLGGetValue(LookupElement(self, "focus_start"));
            f_stop = DLGGetValue(LookupElement(self, "focus_stop"));
            f_step = DLGGetValue(LookupElement(self, "focus_step"));

            SetPersistentStringNote("Acquire Images:Save Folder", folderSave);
            SetPersistentStringNote("Acquire Images:Focus Series:Experiment name", experimentName);
            SetPersistentNumberNote("Acquire Images:Focus Series:Exposure", exp);
            SetPersistentNumberNote("Acquire Images:Focus Series:Start", f_start);
            SetPersistentNumberNote("Acquire Images:Focus Series:Stop", f_stop);
            SetPersistentNumberNote("Acquire Images:Focus Series:Step", f_step);
            SetPersistentNumberNote("Acquire Images:Focus Series:Binning", binning);

            self.setupCamera();
            TagGroup imageSeries = newTagGroup();
            number f_saved = EMGetFocus();
            // This is -0, 5nm for our Libra 200FE. 0nm is not possible.
            EMChangeFocus(-f_start)
            focus = f_start;
            number doNext = 1;
            while (!ShiftDown() && doNext) {
                self.recordImage();
                focus += f_step;
                EMChangeFocus(-f_step)
                if (focus > f_stop | f_step == 0) {
                    doNext = 0;
                }
            }
            EMSetFocus(f_saved);
        }
        self.setElementIsEnabled("idRecord", 1);
    }


    void buttonResponse(object self) {
        self.setElementIsEnabled("idRecord", 0);
        StartThread(self, "runThread");
    }


    TagGroup makeDefaultOptions(object self) {
        TagGroup defaultItems;
        TagGroup defaultBox = DLGCreateBox(" Acquisition settings ", defaultItems);
        defaultBox.DLGInternalPadding(5, 5);
        defaultBox.DLGExternalPadding(5, 5);

        binning = 2;
        exp = 1

        getPersistentStringNote("Acquire Images:Focus Series:Experiment name", experimentName);
        getPersistentNumberNote("Acquire Images:Focus Series:Exposure", binning);
        getPersistentNumberNote("Acquire Images:Focus Series:Binning", binning);

        TagGroup labelExperimentName = DLGCreateLabel("Experiment name");
        TagGroup fieldExperimentName = DLGIdentifier(DLGCreateStringField(experimentName), "Experiment name");
        TagGroup inputExperimentName = DLGGroupItems(labelExperimentName, fieldExperimentName);
        defaultItems.DLGAddElement(inputExperimentName);

        TagGroup labelExposute = DLGCreateLabel("Exposute Time");
        TagGroup fieldExposute = DLGIdentifier(DLGCreateRealField(exp), "Exposure");
        TagGroup inputExposute = DLGGroupItems(labelExposute, fieldExposute);
        defaultItems.DLGAddElement(inputExposute);

        TagGroup labelBinning = DLGCreateLabel("Binning");
        TagGroup fieldBinning = DLGIdentifier(DLGCreateIntegerField(binning), "Binning");
        TagGroup inputBinning = DLGGroupItems(labelBinning, fieldBinning);
        defaultItems.DLGAddElement(inputBinning);

        return defaultBox;
    }


    TagGroup makefocusSeriesOptions(object self) {
        TagGroup focusSeriesItems;
        TagGroup focusSeriesBox = DLGCreateBox(" Focus Series settings ", focusSeriesItems);
        focusSeriesBox.DLGInternalPadding(5, 5);
        focusSeriesBox.DLGExternalPadding(5, 5);

        f_start = f_stop = f_step = 0;
        getPersistentNumberNote("Acquire Images:Focus Series:Start", f_start);
        getPersistentNumberNote("Acquire Images:Focus Series:Stop", f_stop);
        getPersistentNumberNote("Acquire Images:Focus Series:Step", f_step);

        TagGroup labelFocusStart = DLGCreateLabel("Start Focus (nm)");
        TagGroup fieldFocusStart = DLGIdentifier(DLGCreateRealField(f_start), "focus_start");
        TagGroup inputFocusStart = DLGGroupItems(labelFocusStart, fieldFocusStart);
        focusSeriesItems.DLGAddElement(inputFocusStart);

        TagGroup labelFocusStop = DLGCreateLabel("Stop Focus (nm)");
        TagGroup fieldFocusStop = DLGIdentifier(DLGCreateRealField(f_stop), "focus_stop");
        TagGroup inputFocusStop = DLGGroupItems(labelFocusStop, fieldFocusStop);
        focusSeriesItems.DLGAddElement(inputFocusStop);

        TagGroup labelFocusStep = DLGCreateLabel("Focus step (nm)");
        TagGroup fieldFocusStep = DLGIdentifier(DLGCreateRealField(f_step), "focus_step");
        TagGroup inputFocusStep = DLGGroupItems(labelFocusStep, fieldFocusStep);
        focusSeriesItems.DLGAddElement(inputFocusStep);

        return focusSeriesBox;
    }


    TagGroup makeRecordButton(object self) {
        TagGroup recordItems;
        TagGroup recordBox = DLGCreateBox(" Start acquisition ", recordItems);
        recordBox.DLGInternalPadding(5, 5);
        recordBox.DLGExternalPadding(5, 5);

        btnRecord = DLGCreatePushButton("Record", "buttonResponse");
        DLGIdentifier(btnRecord, "idRecord");
        recordItems.DLGAddElement(btnRecord);
        recordItems.DLGAddElement(DLGCreateLabel("Hold down Shift to cancel the recording."));

        return recordBox;
    }


    void initFolderSave(object self) {
        folderSave = "";
        getPersistentStringNote("Acquire Images:Save Folder", folderSave);
        if (folderSave == "") {
            folderSave = GetApplicationDirectory("current", 0);
        }
    }


    TagGroup createDialog(object self) {
				TagGroup position;
        position = DLGBuildPositionFromApplication();
        position.TagGroupSetTagAsTagGroup("Width", DLGBuildAutoSize());
        position.TagGroupSetTagAsTagGroup("Height", DLGBuildAutoSize());
        position.TagGroupSetTagAsTagGroup("X", DLGBuildRelativePosition("Inside", 1));
        position.TagGroupSetTagAsTagGroup("Y", DLGBuildRelativePosition("Inside", 1));
        
        TagGroup dialogItems;
        TagGroup dialog = DLGCreateDialog(title, dialogItems);
        dialog.DLGPosition(position);

        dialogItems.DLGAddElement(self.makeDefaultOptions());
        dialogItems.DLGAddElement(self.makefocusSeriesOptions());
        dialogItems.DLGAddElement(self.makeRecordButton());

        dialogItems.DLGAddElement(DLGCreateLabel(author + ", v." + version + " (" + date + ")"))
        return dialog;
    }


    AcquisitionDialog(object self) {
        self.super.init(self.createDialog());
        self.display(title);
        self.initFolderSave();
    }


}


alloc(AcquisitionDialog);
