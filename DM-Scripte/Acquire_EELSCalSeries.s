String title = "EELS Calibration Series";
String version = "0.2.0";
String date = "February 2017";
String author = "M. Entrup";


// A delay of 59.9 corresponds to 1 second
number DELAY_FACTOR = 59.9;


// This function is used to convert 1eV to 1.0eV
string padRight(number num, number digits) {
    if (digits < 1) {
        return "" + num;
    }
    number toAdd = 0;
    string numberStr = "" + num;
    if (find(numberStr, ".") == -1) {
        numberStr += ".";
        toAdd = digits;
    } else {
        number length = len("" + num);
        toAdd = digits + 1 - (length - find(numberStr, "."));
    }
    for (number i = 0; i < toAdd; i++) {
        numberStr += "0";
    }
    return numberStr;
}


class AcquisitionDialog: uiframe {
 /*
  * AcquisitionDialog is a child of uiframe the default dialog class of DM.
  * In the constructor (see last function of this class) the dialog is created and shown.
  * More examples on how to create dialogs can be found on Dave Mitchell's website:
  * - http://www.dmscripting.com/examples.html
  */


    Object imageAcqPara, CCDCamera;
    TagGroup btnRecord;
    number filterDelay, lastLoss, binning, exposure, energyLoss, readheight;
    string folderSave, experimentName;


    void saveImage(object self, image img) {
        SaveImage(img, folderSave + ImageGetName(img) + ".dm3");
    }


    void setupCamera(object self) {
  /*
   * This method is called once, when starting the acquisition series.
   */
        number CCDWidth, CCDHeight, imageProcessing;

        // Info on imageProcessing:
        // 1 - No dark or gain correction
        // 2 - Dark correction only
        // 3 - Dark and gain correction
        imageProcessing = 3;

        SSCGetSize(CCDWidth, CCDHeight);
        CCDcamera = CM_GetCurrentCamera();
        imageAcqPara = CM_GetCameraAcquisitionParameterSet_HighQualityImagingAcquire(CCDcamera);
        /*
         * For EELS the binning in x-direction is fixed to 8.
         * This is the direction of integration and therefore the lowest resolution is sufficient.
         * In y-direction the user defines the binning. This is the axis of the energy loss.
         * Info: The resulting image will be rotated by 90 deg left (see recordImage()).
         */
        CM_SetBinning(ImageAcqPara, 8, binning);
        CM_SetProcessing(ImageAcqPara, ImageProcessing);
        /*
         * Only a small part of the x-axis is iluminated by the spectrum.
         * To get the best result only a small part of the ist uesed.
         * This script and Change_Read_height.s use the same Persistent Notes to store the selected value.
         * The same value is used by DM for EELS acquisition.
         */
        number cutoff = (CCDHeight - readheight) / 2;
        CM_SetCCDReadArea(ImageAcqPara, 0, cutoff, CCDWidth, CCDHeight-cutoff);
        CM_SetAcqTranspose(ImageAcqPara, CM_Config_GetDefaultTranspose(CCDcamera));
    }


    void recordImage(object self) {
  /*
   * This method is called once, for each image recorded.
   */
        image acquiredImage;

        if (IFGetEnergyLoss() != energyLoss) {
            IFSetEnergyLoss(energyLoss);
            Delay(DELAY_FACTOR * filterDelay);
        }
        CM_SetExposure(ImageAcqPara, exposure);
        acquiredImage = CM_CreateImageForAcquire(CCDcamera, ImageAcqPara, "Record");
        number binX, binY;
        CM_GetBinning(ImageAcqPara, binX, binY);
        if (binX == binY) {
            ImageSetName(acquiredImage, experimentName + "_Bin" + binX + "_" + exposure + "s_" + padRight(energyLoss, 1) + "eV");
        } else {
            ImageSetName(acquiredImage, experimentName + "_Bin" + binX + ", " + binY + "_" + exposure + "s_" + padRight(energyLoss, 1) + "eV");
        }
        CM_AcquireImage(CCDcamera, ImageAcqPara, acquiredImage);
        RotateLeft(acquiredImage);
        SetScale(acquiredImage, 1, 1);
        SetUnitString(acquiredImage, "");
        self.saveImage(acquiredImage);
        showImage(acquiredImage);
    }


    void printAcqInfo(object self, number counter, number imgCount) {
        Number time = GetCurrentTime();
        number dateFormat = 2;
        number timeFormat = 2;
        number format = dateFormat + 16 * timeFormat;
        Result( FormatTimeString( time, format ) + " -- " );
        result("(" + (counter+1) + "/" + imgCount + ") Acquireing image at " + padRight(energyLoss, 1) + "eV." + "\n");
    }


    void runThread(object self) {
        number start, stop, step, imgCount, initLoss, doNext, counter;
        Image eLosses;
        if ( GetDirectoryDialog( "Select folder to save the image series", folderSave, folderSave ) ) {
            initLoss = IFGetEnergyLoss();
            experimentName = DLGGetStringValue(LookupElement(self, "Experiment name"));
            exposure = DLGGetValue(LookupElement(self, "exp"));
            binning = DLGGetValue(LookupElement(self, "Binning"));
            readheight = DLGGetValue(LookupElement(self, "readheight"));

            SetPersistentStringNote("Acquire Images:Save Folder", folderSave);
            SetPersistentStringNote("Acquire Images:Img Spec:Experiment name", experimentName);
            SetPersistentNumberNote("Acquire Images:Img Spec:Start", exposure);
            SetPersistentNumberNote("Acquire Images:Binning", binning);
            SetPersistentNumberNote("EELS:Acquisition:Projection:Read height", readheight);

            start = DLGGetValue(LookupElement(self, "loss_start"));
            stop = DLGGetValue(LookupElement(self, "loss_stop"));
            step = DLGGetValue(LookupElement(self, "loss_step"));

            SetPersistentNumberNote("Acquire Images:Img Spec:Start energy loss", start);
            SetPersistentNumberNote("Acquire Images:Img Spec:Stop energy loss", stop);
            SetPersistentNumberNote("Acquire Images:Img Spec:Energy loss step", step);

            if (step == 0) {
                imgCount = 1;
            } else {
                imgCount = 0;
                number current = start;
                if (start <= stop) {
                    while (current <= stop) {
                        imgCount += 1;
                        current += step;
                    }
                } else {
                    while (current >= stop) {
                        imgCount += 1;
                        current -= step;
                    }
                }
            }
            result("Number of images to acquire: " + imgCount + "\n");
            result((imgCount*exposure) + "s summed exposure time." + "\n");

            /*
              An image is used as an array.
              RealImage( string title, number size, number width, number height )
             */
            eLosses = RealImage("", 4, imgCount, 1);
            if (start <= stop) {
                Number i = 0;
                while (i < imgCount) {
                    setpixel(eLosses, i, 0, start + i * step);
                    i++;
                }
            } else {
                Number i = 0;
                while (i < imgCount) {
                    setpixel(eLosses, i, 0, start - i * step);
                    i++;
                }
            }

            self.setupCamera();
            doNext = 1;
            counter = 0;
            while (!ShiftDown() && doNext) {
                energyLoss = sum(eLosses[0, counter, 1, counter + 1]);
                self.printAcqInfo(counter, imgCount);
                self.recordImage();
                counter++;
                if (counter >= imgCount) doNext = 0;
            }
        }
        IFSetEnergyLoss(initLoss);
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

        number binning, exp, iters, delay;
        binning = 2;
        exp = iters = 1;
        delay = 0;

        getPersistentStringNote("Acquire Images:Img Spec:Experiment name", experimentName);
        getPersistentNumberNote("Acquire Images:Binning", binning);
        getPersistentNumberNote("EELS:Acquisition:Projection:Read height", readheight);        
        getPersistentNumberNote("Acquire Images:Img Spec:Exposure", exp);
        getPersistentNumberNote("Acquire Images:Iteration", iters);
        getPersistentNumberNote("Acquire Images:Delay", delay);

        TagGroup labelExperimentName = DLGCreateLabel("Experiment name");
        TagGroup fieldExperimentName = DLGIdentifier(DLGCreateStringField(experimentName), "Experiment name");
        TagGroup inputExperimentName = DLGGroupItems(labelExperimentName, fieldExperimentName);
        defaultItems.DLGAddElement(inputExperimentName);

        TagGroup labelBinning = DLGCreateLabel("Binning (energy axis)");
        TagGroup fieldBinning = DLGIdentifier(DLGCreateIntegerField(binning), "Binning");
        TagGroup inputBinning = DLGGroupItems(labelBinning, fieldBinning);
        defaultItems.DLGAddElement(inputBinning);

        TagGroup labelReadheight = DLGCreateLabel("Read height (pixel)");
        TagGroup fieldReadheight = DLGIdentifier(DLGCreateIntegerField(readheight), "readheight");
        TagGroup inputReadheight = DLGGroupItems(labelReadheight, fieldReadheight);
        defaultItems.DLGAddElement(inputReadheight);

        TagGroup labelExp = DLGCreateLabel("Acquisition Time (sec)");
        TagGroup fieldExp = DLGIdentifier(DLGCreateRealField(exp), "exp");
        TagGroup inputExp = DLGGroupItems(labelExp, fieldExp);
        defaultItems.DLGAddElement(inputExp);

        return defaultBox;
    }


    TagGroup makeTimeSeriesOptions(object self) {
        TagGroup imgSpecSeriesItems;
        TagGroup imgSpecSeriesBox = DLGCreateBox(" Image Spec settings ", imgSpecSeriesItems);
        imgSpecSeriesBox.DLGInternalPadding(5, 5);
        imgSpecSeriesBox.DLGExternalPadding(5, 5);

        number start, stop, step;
        start = stop = step = 0;

        getPersistentNumberNote("Acquire Images:Img Spec:Start energy loss", start);
        getPersistentNumberNote("Acquire Images:Img Spec:Stop energy loss", stop);
        getPersistentNumberNote("Acquire Images:Img Spec:Energy loss step", step);

        TagGroup labelLossStart = DLGCreateLabel("Start energy loss (eV)");
        TagGroup fieldLossStart = DLGIdentifier(DLGCreateRealField(start), "loss_start");
        TagGroup inputLossStart = DLGGroupItems(labelLossStart, fieldLossStart);
        imgSpecSeriesItems.DLGAddElement(inputLossStart);

        TagGroup labelLossStop = DLGCreateLabel("Stop energy loss (eV)");
        TagGroup fieldLossStop = DLGIdentifier(DLGCreateRealField(stop), "loss_stop");
        TagGroup inputLossStop = DLGGroupItems(labelLossStop, fieldLossStop);
        imgSpecSeriesItems.DLGAddElement(inputLossStop);

        TagGroup labelLossStep = DLGCreateLabel("Energy loss step (eV)");
        TagGroup fieldLossStep = DLGIdentifier(DLGCreateRealField(step), "loss_step");
        TagGroup inputLossStep = DLGGroupItems(labelLossStep, fieldLossStep);
        imgSpecSeriesItems.DLGAddElement(inputLossStep);

        return imgSpecSeriesBox;
    }


    TagGroup makeRecordButton(object self) {
        TagGroup recordItems;
        TagGroup recordBox = DLGCreateBox(" Start acquisition ", recordItems);
        recordBox.DLGInternalPadding(5, 5);
        recordBox.DLGExternalPadding(5, 5);

        btnRecord = DLGCreatePushButton("Record", "buttonResponse");
        DLGIdentifier(btnRecord, "idRecord");
        recordItems.DLGAddElement(btnRecord);
        recordItems.DLGAddElement(DLGCreateLabel("Hold down [Shift] to cancel the recording."));

        return recordBox;
    }


    void initFolderSave(object self) {
        folderSave = "";
        getPersistentStringNote("Acquire Images:Save Folder", folderSave);
        if ( folderSave == "" ) {
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
        dialog.DLGPosition(position)

        dialogItems.DLGAddElement(self.makeDefaultOptions());
        dialogItems.DLGAddElement(self.makeTimeSeriesOptions());
        dialogItems.DLGAddElement(self.makeRecordButton());

        dialogItems.DLGAddElement(DLGCreateLabel(author + ", v." + version + " (" + date + ")"))
        return dialog;
    }


    AcquisitionDialog(object self) {
        self.super.init(self.createDialog());
        filterDelay = 1;
        self.display(title);
        self.initFolderSave();
    }


}


alloc(AcquisitionDialog);
