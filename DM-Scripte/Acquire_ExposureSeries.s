String title = "Exposure Series";
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
        number binning, exposure;
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

                CM_SetExposure(ImageAcqPara, exposure);
                acquiredImage = CM_CreateImageForAcquire(CCDcamera, ImageAcqPara, "Record");
                ImageSetName(acquiredImage, experimentName + "_Bin" + binning + "_" + exposure + "s");
                CM_AcquireImage(CCDcamera, ImageAcqPara, acquiredImage)
                fliphorizontal(acquiredImage);
                self.saveImage(acquiredImage);
                showImage(acquiredImage);
        }


        void runThread(object self) {
                number stop, step;
                if (GetDirectoryDialog("Select folder to save the image series", folderSave, folderSave)) {
                        experimentName = DLGGetStringValue(LookupElement(self, "Experiment name"));
                        exposure = DLGGetValue(LookupElement(self, "time_start"));
                        stop = DLGGetValue(LookupElement(self, "time_stop"));
                        step = DLGGetValue(LookupElement(self, "time_step"));
                        binning = DLGGetValue(LookupElement(self, "Binning"));

                        SetPersistentStringNote("Acquire Images:Save Folder", folderSave);
                        SetPersistentStringNote("Acquire Images:Time Series:Experiment name", experimentName);
                        SetPersistentNumberNote("Acquire Images:Time Series:Start", exposure);
                        SetPersistentNumberNote("Acquire Images:Time Series:Stop", stop);
                        SetPersistentNumberNote("Acquire Images:Time Series:Step", step);
                        SetPersistentNumberNote("Acquire Images:Binning", binning);

                        self.setupCamera();
                        TagGroup imageSeries = newTagGroup();
                        number doNext = 1
                                        while (!ShiftDown() && doNext) {
                                self.recordImage();
                                exposure += step;
                                if (exposure > stop) {
                                        doNext = 0;
                                }
                        }
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
                defaultBox.DLGExternalPadding(5, 5);
                defaultBox.DLGInternalPadding(5, 5);

                number binning;
                binning = 2;

                getPersistentStringNote("Acquire Images:Time Series:Experiment name", experimentName);
                getPersistentNumberNote("Acquire Images:Binning", binning);

                TagGroup labelExperimentName = DLGCreateLabel("Experiment name");
                TagGroup fieldExperimentName = DLGIdentifier(DLGCreateStringField(experimentName), "Experiment name");
                TagGroup inputExperimentName = DLGGroupItems(labelExperimentName, fieldExperimentName);
                defaultItems.DLGAddElement(inputExperimentName);

                TagGroup labelBinning = DLGCreateLabel("Binning")
                                        TagGroup fieldBinning = DLGIdentifier(DLGCreateIntegerField(binning), "Binning")
                                                                TagGroup inputBinning = DLGGroupItems(labelBinning, fieldBinning)
                                                                                        defaultItems.DLGAddElement(inputBinning);

                return defaultBox;
        }


        TagGroup makeTimeSeriesOptions(object self) {
                TagGroup timeSeriesItems;
                TagGroup timeSeriesBox = DLGCreateBox(" Time Series settings ", timeSeriesItems);
                timeSeriesBox.DLGInternalPadding(5, 5);
                timeSeriesBox.DLGInternalPadding(5, 5);

                number start, stop, step;
                start = stop = step = 1;
                getPersistentNumberNote("Acquire Images:Time Series:Start", start);
                getPersistentNumberNote("Acquire Images:Time Series:Stop", stop);
                getPersistentNumberNote("Acquire Images:Time Series:Step", step);

                TagGroup labelTimeStart = DLGCreateLabel("Start Acquisition Time (sec)");
                TagGroup fieldTimeStart = DLGIdentifier(DLGCreateRealField(start), "time_start");
                TagGroup inputTimeStart = DLGGroupItems(labelTimeStart, fieldTimeStart);
                timeSeriesItems.DLGAddElement(inputTimeStart);

                TagGroup labelTimeStop = DLGCreateLabel("Stop Acquisition Time (sec)");
                TagGroup fieldTimeStop = DLGIdentifier(DLGCreateRealField(stop), "time_stop");
                TagGroup inputTimeStop = DLGGroupItems(labelTimeStop, fieldTimeStop);
                timeSeriesItems.DLGAddElement(inputTimeStop);

                TagGroup labelTimeStep = DLGCreateLabel("Acquisition Time step (sec)");
                TagGroup fieldTimeStep = DLGIdentifier(DLGCreateRealField(step), "time_step");
                TagGroup inputTimeStep = DLGGroupItems(labelTimeStep, fieldTimeStep);
                timeSeriesItems.DLGAddElement(inputTimeStep);

                return timeSeriesBox;
        }


        TagGroup makeRecordButton(object self) {
                TagGroup recordItems;
                TagGroup recordBox = DLGCreateBox(" Start acquisition ", recordItems);
                recordBox.DLGInternalPadding(5, 5);
                recordBox.DLGInternalPadding(5, 5);

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
                TagGroup dialog = DLGCreateDialog("Acquisition Dialog", dialogItems);
                dialog.DLGPosition(position);

                dialogItems.DLGAddElement(self.makeDefaultOptions());
                dialogItems.DLGAddElement(self.makeTimeSeriesOptions());
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
