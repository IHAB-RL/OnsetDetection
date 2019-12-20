classdef OnsetDetection < handle
    
    properties
        
        sPath_Images = 'images';
        hFig;
        vScreenSize;
        hAx1;
        hAx2;
        hAx3;
        hText_Message;
        hText_Message_BG;
        hPanel_Axes;
        hPanel_Controls;
        hAxVis;
        hPatchVis;
        
        hPanel_ViewControls
        hButton_Left;
        hButton_Right;
        hButton_Max;
        hButton_Min;
        hButton_Home;
        sFile_Icon_Arrow_left = 'icon_Arrow_left.png';
        sFile_Icon_Arrow_right = 'icon_Arrow_right.png';
        sFile_Icon_Arrow_min = 'icon_Arrow_min.png';
        sFile_Icon_Arrow_max = 'icon_Arrow_max.png';
        sFile_Icon_Home = 'icon_home.png';
        
        hButton_File;
        hText_File;
        hText_Length;
        hEdit_Length;
        hText_Blocklen;
        hEdit_Blocklen;
        hEdit_Base_LP;
        hEdit_Base_BP;
        hEdit_Base_HP;
        hEdit_Base_WB;
        hText_Base;
        hEdit_P1_LP;
        hEdit_P1_BP;
        hEdit_P1_HP;
        hEdit_P1_WB;
        hText_P1;
        hEdit_P2_LP;
        hEdit_P2_BP;
        hEdit_P2_HP;
        hEdit_P2_WB;
        hText_P2;
        hEdit_tauFast_LP;
        hEdit_tauFast_BP;
        hEdit_tauFast_HP;
        hEdit_tauFast_WB;
        hText_tauFast;
        hEdit_tauSlow_LP;
        hEdit_tauSlow_BP;
        hEdit_tauSlow_HP;
        hEdit_tauSlow_WB;
        hText_tauSlow;
        
        nFillControl_Vertical;
        nFillControl_Horizontal = 10;
        nEditControls_Width;
        nEditControls_Height;
        
        nMessageWidth = 120;
        nMessageHeight = 24;
        
        nMagnification = 1;
        nMagFactor = 1.5;
        nShiftFactor = 0.25;
        vXLim_orig;
        vAusschnitt;
        
        nHeightFig = 600 + 20;
        nWidthFig = 800;
        nAxisWidth = 540;
        nAxisHeight = 193;
        nAxisFill_Horizontal = 20;
        nAxisFill_Vertical = 20;
        nLabelHeight = 20;
        nViewControl_Height = 150;
        nViewControl_Width;
        nViewControl_FillHorizontal;
        nViewControl_FillVertical;
        nButtonViewControl_Width = 45;
        nButtonViewControl_Height = 30;
        mColor;
        
        vColor_Marker = [0.7, 0.7, 0.7];
        vBackgroundColor = [0.7, 0.7, 0.7];
        source;
        sFileName = '';
        sPathName;
        vSignal;
        vSignal_orig;
        nFs;
        % Length of Signal
        nTimeWindow = 10;
        
        % Parameters
        nParameter_BlockSize = 32;
        % influences threshold_raise
        vParameter_1 = [4, 4, 4, 4]*2;
        % influences decay of threshold_raise
        vParameter_2 = log10([9.99, 9.98, 9.97, 9.99]);
        vParameter_ThreshBase = [4, 4, 4, 4]*2-2;
        vParameter_TauFast = [1, 1, 1, 1];
        vParameter_TauSlow = [20, 20, 20, 20];
        
        nChannels = 4;
        
        vPeakLoc;
        mThresh_hist;
        
        Zi_fast_lp = 0;
        Zi_slow_lp = 0;
        Zi_fast_bp = 0;
        Zi_slow_bp = 0;
        Zi_fast_hp = 0;
        Zi_slow_hp = 0;
        Zi_fast_wb = 0;
        Zi_slow_wb = 0;
        
        vEnergRatio_LP;
        vEnergRatio_BP;
        vEnergRatio_HP;
        vEnergRatio_WB;
        
        vOut_LP;
        vOut_BP;
        vOut_HP;
       
    end
    
    
    methods
        
        function [obj] = OnsetDetection()
            
            addpath([pwd, filesep, obj.sPath_Images]);
            
            obj.nEditControls_Height = obj.nButtonViewControl_Height;
            
            obj.nViewControl_Width = obj.nWidthFig - ...
                obj.nAxisWidth - 2 * obj.nAxisFill_Horizontal;
            
            obj.nViewControl_FillHorizontal = round(obj.nViewControl_Width - ...
                3 * obj.nButtonViewControl_Width)/2;
            
            obj.nViewControl_FillVertical = round(obj.nViewControl_Height - ...
                obj.nLabelHeight  -  3 * obj.nButtonViewControl_Height)/2;
            
            obj.nFillControl_Vertical = (obj.nHeightFig - ...
                obj.nLabelHeight - obj.nViewControl_Height - ...
                7 * obj.nButtonViewControl_Height) / 8;
            
            obj.nEditControls_Width = (obj.nViewControl_Width - ...
                5 * obj.nFillControl_Horizontal) / 4;
            
            set(0,'Units','Pixels') ;
            obj.vScreenSize = get(0,'screensize');
            
            obj.mColor = [
                0    0.4470    0.7410;
                0.8500    0.3250    0.0980;
                0.9290    0.6940    0.1250;
                0.4940    0.1840    0.5560;
                0.4660    0.6740    0.1880;
                0.3010    0.7450    0.9330;
                0.6350    0.0780    0.1840];
            
            obj.GUI();
            obj.setEditable(false)
            
            
        end
        
        function [] = GUI(obj)
            
            % Main Figure
            
            obj.hFig = uifigure();
            obj.hFig.Position = [(obj.vScreenSize(3)-obj.nWidthFig)/2,...
                (obj.vScreenSize(4)-obj.nHeightFig)/2, ...
                obj.nWidthFig, obj.nHeightFig];
            obj.hFig.Name = 'Onset Detection';
            obj.hFig.Resize = 'Off';
            obj.hFig.Color = obj.vBackgroundColor;
            
            % Panel: Axes
            
            obj.hPanel_Axes = uipanel(obj.hFig);
            obj.hPanel_Axes.Units = 'Pixel';
            obj.hPanel_Axes.Position = [1, 1, ...
                obj.nAxisWidth + 2 * obj.nAxisFill_Horizontal, obj.nHeightFig];
            obj.hPanel_Axes.Title = 'Axes';
            
            obj.hAx3 = axes(obj.hPanel_Axes);
            obj.hAx3.Units = 'Pixel';
            obj.hAx3.Position = [obj.nAxisFill_Horizontal + 1, obj.nAxisFill_Vertical + 1, ...
                obj.nAxisWidth, obj.nAxisHeight];
            obj.hAx3.XTick = [];
            obj.hAx3.YTick = [];
            obj.hAx3.Visible = 'off';
            
            obj.hAx2 = axes(obj.hPanel_Axes);
            obj.hAx2.Units = 'Pixel';
            obj.hAx2.Position = [obj.nAxisFill_Horizontal + 1, obj.nAxisHeight + ...
                1 * obj.nAxisFill_Vertical, ...
                obj.nAxisWidth, obj.nAxisHeight];
            obj.hAx2.XTick = [];
            obj.hAx2.YTick = [];
            obj.hAx2.Visible = 'off';
            
            obj.hAx1 = axes(obj.hPanel_Axes);
            obj.hAx1.Units = 'Pixel';
            obj.hAx1.Position = [obj.nAxisFill_Horizontal + 1, 2*obj.nAxisHeight + ...
                1 * obj.nAxisFill_Vertical - 1, ...
                obj.nAxisWidth, obj.nAxisHeight];
            obj.hAx1.XTick = [];
            obj.hAx1.YTick = [];
            obj.hAx1.Visible = 'off';

            obj.hText_Message_BG = uilabel(obj.hPanel_Axes);
            obj.hText_Message_BG.Position = [(obj.nAxisWidth - obj.nMessageWidth + 2 * obj.nAxisFill_Horizontal)/2 - 1,...
                (obj.nHeightFig - obj.nMessageHeight)/2 - 1, ...
                obj.nMessageWidth + 2, obj.nMessageHeight + 2];
            obj.hText_Message_BG.Text = 'Calculating';
            obj.hText_Message_BG.Visible = 'off';
            obj.hText_Message_BG.HorizontalAlignment = 'center';
            obj.hText_Message_BG.BackgroundColor = [0,0,0];
            
            obj.hText_Message = uilabel(obj.hPanel_Axes);
            obj.hText_Message.Position = [(obj.nAxisWidth - obj.nMessageWidth + 2 * obj.nAxisFill_Horizontal)/2,...
                (obj.nHeightFig - obj.nMessageHeight)/2, ...
                obj.nMessageWidth, obj.nMessageHeight];
            obj.hText_Message.Text = 'Calculating';
            obj.hText_Message.Visible = 'off';
            obj.hText_Message.HorizontalAlignment = 'center';
            obj.hText_Message.BackgroundColor = [1,1,1];

            % Panel: Controls
            
            obj.hPanel_Controls = uipanel(obj.hFig);
            obj.hPanel_Controls.Units = 'Pixel';
            obj.hPanel_Controls.Position = ...
                [obj.nAxisWidth + 2 * obj.nAxisFill_Horizontal, ...
                obj.nViewControl_Height, ...
                obj.nWidthFig - obj.nAxisWidth - 2 * obj.nAxisFill_Horizontal, ...
                obj.nHeightFig - obj.nViewControl_Height + 1];
            obj.hPanel_Controls.Title = 'Controls';
            
            
            
            nLeft = (obj.hPanel_Controls.Position(3) - obj.nMessageWidth)/2;
            
            
            % Tau Slow
            
            obj.hText_tauSlow = uilabel(obj.hPanel_Controls);
            obj.hText_tauSlow.Position = [nLeft, ...
                1 * obj.nFillControl_Vertical + 1 * obj.nEditControls_Height, ...
                obj.nMessageWidth, obj.nMessageHeight];
            obj.hText_tauSlow.Text = 'Tau Slow:';
            obj.hText_tauSlow.HorizontalAlignment = 'center';
            obj.hText_tauSlow.FontColor = [0.4, 0.4, 0.4];
            
            obj.hEdit_tauSlow_WB = uieditfield(obj.hPanel_Controls);
            obj.hEdit_tauSlow_WB.Position = [obj.nFillControl_Horizontal, ...
                obj.nFillControl_Vertical, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_tauSlow_WB.Value = sprintf('%.2f', obj.vParameter_TauSlow(1));
            obj.hEdit_tauSlow_WB.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_tauSlow_WB.FontColor = obj.mColor(1, :);
            
            obj.hEdit_tauSlow_LP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_tauSlow_LP.Position = [2 * obj.nFillControl_Horizontal + obj.nEditControls_Width, ...
                obj.nFillControl_Vertical, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_tauSlow_LP.Value = sprintf('%.2f', obj.vParameter_TauSlow(2));
            obj.hEdit_tauSlow_LP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_tauSlow_LP.FontColor = obj.mColor(2, :);
            
            obj.hEdit_tauSlow_BP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_tauSlow_BP.Position = [3 * obj.nFillControl_Horizontal + 2 * obj.nEditControls_Width, ...
                obj.nFillControl_Vertical, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_tauSlow_BP.Value = sprintf('%.2f', obj.vParameter_TauSlow(3));
            obj.hEdit_tauSlow_BP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_tauSlow_BP.FontColor = obj.mColor(3, :);
            
            obj.hEdit_tauSlow_HP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_tauSlow_HP.Position = [4 * obj.nFillControl_Horizontal + 3 * obj.nEditControls_Width, ...
                obj.nFillControl_Vertical, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_tauSlow_HP.Value = sprintf('%.2f', obj.vParameter_TauSlow(4));
            obj.hEdit_tauSlow_HP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_tauSlow_HP.FontColor = obj.mColor(4, :);
            
            % Tau Fast
            
            obj.hText_tauFast = uilabel(obj.hPanel_Controls);
            obj.hText_tauFast.Position = [nLeft, ...
                2 * obj.nFillControl_Vertical + 2 * obj.nEditControls_Height, ...
                obj.nMessageWidth, obj.nMessageHeight];
            obj.hText_tauFast.Text = 'Tau Fast:';
            obj.hText_tauFast.HorizontalAlignment = 'center';
            obj.hText_tauFast.FontColor = [0.4, 0.4, 0.4];
            
            obj.hEdit_tauFast_WB = uieditfield(obj.hPanel_Controls);
            obj.hEdit_tauFast_WB.Position = [obj.nFillControl_Horizontal, ...
                2 * obj.nFillControl_Vertical + obj.nEditControls_Height, ...
                obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_tauFast_WB.Value = sprintf('%.2f', obj.vParameter_TauFast(1));
            obj.hEdit_tauFast_WB.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_tauFast_WB.FontColor = obj.mColor(1, :);
            
            obj.hEdit_tauFast_LP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_tauFast_LP.Position = [2 * obj.nFillControl_Horizontal + obj.nEditControls_Width, ...
                2 * obj.nFillControl_Vertical + obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_tauFast_LP.Value = sprintf('%.2f', obj.vParameter_TauFast(2));
            obj.hEdit_tauFast_LP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_tauFast_LP.FontColor = obj.mColor(2, :);
            
            obj.hEdit_tauFast_BP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_tauFast_BP.Position = [3 * obj.nFillControl_Horizontal + 2 * obj.nEditControls_Width, ...
                2 * obj.nFillControl_Vertical + obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_tauFast_BP.Value = sprintf('%.2f', obj.vParameter_TauFast(3));
            obj.hEdit_tauFast_BP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_tauFast_BP.FontColor = obj.mColor(3, :);
            
            obj.hEdit_tauFast_HP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_tauFast_HP.Position = [4 * obj.nFillControl_Horizontal + 3 * obj.nEditControls_Width, ...
                2 * obj.nFillControl_Vertical + obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_tauFast_HP.Value = sprintf('%.2f', obj.vParameter_TauFast(4));
            obj.hEdit_tauFast_HP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_tauFast_HP.FontColor = obj.mColor(4, :);
            
            % Param 2
            
            obj.hText_P2 = uilabel(obj.hPanel_Controls);
            obj.hText_P2.Position = [nLeft, ...
                3 * obj.nFillControl_Vertical + 3 * obj.nEditControls_Height, ...
                obj.nMessageWidth, obj.nMessageHeight];
            obj.hText_P2.Text = 'Parameter 2:';
            obj.hText_P2.HorizontalAlignment = 'center';
            obj.hText_P2.FontColor = [0.4, 0.4, 0.4];
            
            obj.hEdit_P2_WB = uieditfield(obj.hPanel_Controls);
            obj.hEdit_P2_WB.Position = [obj.nFillControl_Horizontal, ...
                3 * obj.nFillControl_Vertical + 2 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_P2_WB.Value = sprintf('%.2f', obj.vParameter_2(1));
            obj.hEdit_P2_WB.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_P2_WB.FontColor = obj.mColor(1, :);
            
            obj.hEdit_P2_LP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_P2_LP.Position = [2 * obj.nFillControl_Horizontal + obj.nEditControls_Width, ...
                3 * obj.nFillControl_Vertical + 2 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_P2_LP.Value = sprintf('%.2f', obj.vParameter_2(2));
            obj.hEdit_P2_LP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_P2_LP.FontColor = obj.mColor(2, :);
            
            obj.hEdit_P2_BP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_P2_BP.Position = [3 * obj.nFillControl_Horizontal + 2 * obj.nEditControls_Width, ...
                3 * obj.nFillControl_Vertical + 2 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_P2_BP.Value = sprintf('%.2f', obj.vParameter_2(3));
            obj.hEdit_P2_BP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_P2_BP.FontColor = obj.mColor(3, :);
            
            obj.hEdit_P2_HP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_P2_HP.Position = [4 * obj.nFillControl_Horizontal + 3 * obj.nEditControls_Width, ...
                3 * obj.nFillControl_Vertical + 2 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_P2_HP.Value = sprintf('%.2f', obj.vParameter_2(4));
            obj.hEdit_P2_HP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_P2_HP.FontColor = obj.mColor(4, :);
            
            % Param 1
            
            obj.hText_P1 = uilabel(obj.hPanel_Controls);
            obj.hText_P1.Position = [nLeft, ...
                4 * obj.nFillControl_Vertical + 4 * obj.nEditControls_Height, ...
                obj.nMessageWidth, obj.nMessageHeight];
            obj.hText_P1.Text = 'Parameter 1:';
            obj.hText_P1.HorizontalAlignment = 'center';
            obj.hText_P1.FontColor = [0.4, 0.4, 0.4];
            
            obj.hEdit_P1_WB = uieditfield(obj.hPanel_Controls);
            obj.hEdit_P1_WB.Position = [obj.nFillControl_Horizontal, ...
                4 * obj.nFillControl_Vertical + 3 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_P1_WB.Value = sprintf('%.2f', obj.vParameter_1(1));
            obj.hEdit_P1_WB.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_P1_WB.FontColor = obj.mColor(1, :);
            
            obj.hEdit_P1_LP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_P1_LP.Position = [2 * obj.nFillControl_Horizontal + obj.nEditControls_Width, ...
                4 * obj.nFillControl_Vertical + 3 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_P1_LP.Value = sprintf('%.2f', obj.vParameter_1(2));
            obj.hEdit_P1_LP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_P1_LP.FontColor = obj.mColor(2, :);
            
            obj.hEdit_P1_BP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_P1_BP.Position = [3 * obj.nFillControl_Horizontal + 2 * obj.nEditControls_Width, ...
                4 * obj.nFillControl_Vertical + 3 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_P1_BP.Value = sprintf('%.2f', obj.vParameter_1(3));
            obj.hEdit_P1_BP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_P1_BP.FontColor = obj.mColor(3, :);
            
            obj.hEdit_P1_HP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_P1_HP.Position = [4 * obj.nFillControl_Horizontal + 3 * obj.nEditControls_Width, ...
                4 * obj.nFillControl_Vertical + 3 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_P1_HP.Value = sprintf('%.2f', obj.vParameter_1(4));
            obj.hEdit_P1_HP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_P1_HP.FontColor = obj.mColor(4, :);
            
            % Base
            
            obj.hText_Base = uilabel(obj.hPanel_Controls);
            obj.hText_Base.Position = [nLeft, ...
                5 * obj.nFillControl_Vertical + 5 * obj.nEditControls_Height, ...
                obj.nMessageWidth, obj.nMessageHeight];
            obj.hText_Base.Text = 'Base:';
            obj.hText_Base.HorizontalAlignment = 'center';
            obj.hText_Base.FontColor = [0.4, 0.4, 0.4];
            
            obj.hEdit_Base_WB = uieditfield(obj.hPanel_Controls);
            obj.hEdit_Base_WB.Position = [obj.nFillControl_Horizontal, ...
                5 * obj.nFillControl_Vertical + 4 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_Base_WB.Value = sprintf('%.2f', obj.vParameter_ThreshBase(1));
            obj.hEdit_Base_WB.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_Base_WB.FontColor = obj.mColor(1, :);
            
            obj.hEdit_Base_LP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_Base_LP.Position = [2 * obj.nFillControl_Horizontal + obj.nEditControls_Width, ...
                5 * obj.nFillControl_Vertical + 4 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_Base_LP.Value = sprintf('%.2f', obj.vParameter_ThreshBase(2));
            obj.hEdit_Base_LP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_Base_LP.FontColor = obj.mColor(2, :);
            
            obj.hEdit_Base_BP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_Base_BP.Position = [3 * obj.nFillControl_Horizontal + 2 * obj.nEditControls_Width, ...
                5 * obj.nFillControl_Vertical + 4 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_Base_BP.Value = sprintf('%.2f', obj.vParameter_ThreshBase(3));
            obj.hEdit_Base_BP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_Base_BP.FontColor = obj.mColor(3, :);
            
            obj.hEdit_Base_HP = uieditfield(obj.hPanel_Controls);
            obj.hEdit_Base_HP.Position = [4 * obj.nFillControl_Horizontal + 3 * obj.nEditControls_Width, ...
                5 * obj.nFillControl_Vertical + 4 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_Base_HP.Value = sprintf('%.2f', obj.vParameter_ThreshBase(4));
            obj.hEdit_Base_HP.ValueChangedFcn = @obj.callbackValueChanged;
            obj.hEdit_Base_HP.FontColor = obj.mColor(4, :);
            
            % Logistics
            obj.hText_Length = uilabel(obj.hPanel_Controls);
            obj.hText_Length.Position = [1 * obj.nFillControl_Horizontal, ...
                6 * obj.nFillControl_Vertical + 5 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hText_Length.Text = sprintf('Length:');
            obj.hText_Length.FontColor = [0.4, 0.4, 0.4];
            
            obj.hEdit_Length = uieditfield(obj.hPanel_Controls);
            obj.hEdit_Length.Position = [2 * obj.nFillControl_Horizontal + obj.nEditControls_Width, ...
                6 * obj.nFillControl_Vertical + 5 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_Length.Value = sprintf('%.2f', obj.nTimeWindow);
            obj.hEdit_Length.ValueChangedFcn = @obj.callbackValueChanged;
            
            obj.hText_Blocklen = uilabel(obj.hPanel_Controls);
            obj.hText_Blocklen.Position = [3 * obj.nFillControl_Horizontal + 2 * obj.nEditControls_Width, ...
                6 * obj.nFillControl_Vertical + 5 * obj.nEditControls_Height, obj.nEditControls_Width+10, obj.nEditControls_Height];
            obj.hText_Blocklen.Text = sprintf('Block:');
            obj.hText_Blocklen.FontColor = [0.4, 0.4, 0.4];
            
            obj.hEdit_Blocklen = uieditfield(obj.hPanel_Controls);
            obj.hEdit_Blocklen.Position = [4 * obj.nFillControl_Horizontal + 3 * obj.nEditControls_Width, ...
                6 * obj.nFillControl_Vertical + 5 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hEdit_Blocklen.Value = sprintf('%d', obj.nParameter_BlockSize);
            obj.hEdit_Blocklen.ValueChangedFcn = @obj.callbackValueChanged;
           
            % File
            obj.hButton_File = uibutton(obj.hPanel_Controls);
            obj.hButton_File.Position = [obj.nFillControl_Horizontal, ...
                7 * obj.nFillControl_Vertical + 6 * obj.nEditControls_Height, obj.nEditControls_Width, obj.nEditControls_Height];
            obj.hButton_File.Text = 'Open';
            obj.hButton_File.ButtonPushedFcn = @obj.callbackOpen;
            
            obj.hText_File = uieditfield(obj.hPanel_Controls);
            obj.hText_File.Position = [2 * obj.nFillControl_Horizontal + obj.nEditControls_Width, ...
                7 * obj.nFillControl_Vertical + 6 * obj.nEditControls_Height, ...
                3 * obj.nEditControls_Width + 2 * obj.nFillControl_Horizontal, obj.nEditControls_Height];
            obj.hText_File.Value = obj.sFileName;
            obj.hText_File.Editable = 'off';
            
            % Panel: View Controls
            
            obj.hPanel_ViewControls = uipanel(obj.hFig);
            obj.hPanel_ViewControls.Units = 'Pixel';
            obj.hPanel_ViewControls.Position = [obj.nWidthFig - obj.nViewControl_Width, 1, ...
                obj.nViewControl_Width, obj.nViewControl_Height];
            obj.hPanel_ViewControls.Title = 'View Controls';
            
            obj.hButton_Left = uibutton(obj.hPanel_ViewControls);
            obj.hButton_Left.Position = [obj.nViewControl_FillHorizontal, ...
                obj.nViewControl_FillVertical + obj.nButtonViewControl_Height, ...
                obj.nButtonViewControl_Width, obj.nButtonViewControl_Height];
            obj.hButton_Left.Text = '';
            obj.hButton_Left.Icon = obj.sFile_Icon_Arrow_left;
            obj.hButton_Left.ButtonPushedFcn = @obj.callbackLeft;
            
            obj.hButton_Right = uibutton(obj.hPanel_ViewControls);
            obj.hButton_Right.Position = [obj.nViewControl_FillHorizontal + 2 * obj.nButtonViewControl_Width, ...
                obj.nViewControl_FillVertical + obj.nButtonViewControl_Height, ...
                obj.nButtonViewControl_Width, obj.nButtonViewControl_Height];
            obj.hButton_Right.Text = '';
            obj.hButton_Right.Icon = obj.sFile_Icon_Arrow_right;
            obj.hButton_Right.ButtonPushedFcn = @obj.callbackRight;
            
            obj.hButton_Max = uibutton(obj.hPanel_ViewControls);
            obj.hButton_Max.Position = [obj.nViewControl_FillHorizontal + 1 * obj.nButtonViewControl_Width, ...
                obj.nViewControl_FillVertical + 2 * obj.nButtonViewControl_Height, ...
                obj.nButtonViewControl_Width, obj.nButtonViewControl_Height];
            obj.hButton_Max.Text = '';
            obj.hButton_Max.Icon = obj.sFile_Icon_Arrow_max;
            obj.hButton_Max.ButtonPushedFcn = @obj.callbackMax;
            
            obj.hButton_Min = uibutton(obj.hPanel_ViewControls);
            obj.hButton_Min.Position = [obj.nViewControl_FillHorizontal + 1 * obj.nButtonViewControl_Width, ...
                obj.nViewControl_FillVertical, ...
                obj.nButtonViewControl_Width, obj.nButtonViewControl_Height];
            obj.hButton_Min.Text = '';
            obj.hButton_Min.Icon = obj.sFile_Icon_Arrow_min;
            obj.hButton_Min.ButtonPushedFcn = @obj.callbackMin;
            
            obj.hButton_Home = uibutton(obj.hPanel_ViewControls);
            obj.hButton_Home.Position = [obj.nViewControl_FillHorizontal + 1 * obj.nButtonViewControl_Width, ...
                obj.nViewControl_FillVertical + obj.nButtonViewControl_Height, ...
                obj.nButtonViewControl_Width, obj.nButtonViewControl_Height];
            obj.hButton_Home.Text = '';
            obj.hButton_Home.Icon = obj.sFile_Icon_Home;
            obj.hButton_Home.ButtonPushedFcn = @obj.callbackHome;

        end
        
        function [] = setEditable(obj, editable, ~, ~)
            
            if editable
                
                vPatches = findall(obj.hFig, 'Type', 'patch');
                for iPatch = 1:length(vPatches)
                    vPatches(iPatch).delete();
                end
                
                obj.hText_Length.Enable = 'on';
                obj.hText_Blocklen.Enable = 'on';
                obj.hText_Base.Enable = 'on';
                obj.hText_P1.Enable = 'on';
                obj.hText_P2.Enable = 'on';
                obj.hText_tauFast.Enable = 'on';
                obj.hText_tauSlow.Enable = 'on';
                obj.hButton_File.Enable = 'on';
                obj.hEdit_Length.Enable = 'on';
                obj.hEdit_Blocklen.Enable = 'on';
                obj.hButton_Left.Enable = 'on';
                obj.hButton_Right.Enable = 'on';
                obj.hButton_Max.Enable = 'on';
                obj.hButton_Min.Enable = 'on';
                obj.hButton_Home.Enable = 'on';
                obj.hEdit_Base_WB.Enable = 'on';
                obj.hEdit_Base_LP.Enable = 'on';
                obj.hEdit_Base_BP.Enable = 'on';
                obj.hEdit_Base_HP.Enable = 'on';
                obj.hEdit_P1_WB.Enable = 'on';
                obj.hEdit_P1_LP.Enable = 'on';
                obj.hEdit_P1_BP.Enable = 'on';
                obj.hEdit_P1_HP.Enable = 'on';
                obj.hEdit_P2_WB.Enable = 'on';
                obj.hEdit_P2_LP.Enable = 'on';
                obj.hEdit_P2_BP.Enable = 'on';
                obj.hEdit_P2_HP.Enable = 'on';
                obj.hEdit_tauFast_WB.Enable = 'on';
                obj.hEdit_tauFast_LP.Enable = 'on';
                obj.hEdit_tauFast_BP.Enable = 'on';
                obj.hEdit_tauFast_HP.Enable = 'on';
                obj.hEdit_tauSlow_WB.Enable = 'on';
                obj.hEdit_tauSlow_LP.Enable = 'on';
                obj.hEdit_tauSlow_BP.Enable = 'on';
                obj.hEdit_tauSlow_HP.Enable = 'on';
                
                obj.hText_Message_BG.Visible = 'off';
                obj.hText_Message.Visible = 'off';

            else
                
                vPatches = findall(obj.hFig, 'Type', 'patch');
                for iPatch = 1:length(vPatches)
                    vPatches(iPatch).delete();
                end
                
                patch(obj.hAx1, [obj.hAx1.XLim(1),obj.hAx1.XLim(1),...
                    obj.hAx1.XLim(2),obj.hAx1.XLim(2)],[obj.hAx1.YLim(1),...
                    obj.hAx1.YLim(2),obj.hAx1.YLim(2),obj.hAx1.YLim(1)], ...
                    [1,1,1], ...
                    'FaceAlpha', 0.5, 'EdgeColor', 'none');
                patch(obj.hAx2, [obj.hAx2.XLim(1),obj.hAx2.XLim(1),...
                    obj.hAx2.XLim(2),obj.hAx2.XLim(2)],[obj.hAx2.YLim(1),...
                    obj.hAx2.YLim(2),obj.hAx2.YLim(2),obj.hAx2.YLim(1)], ...
                    [1,1,1], ...
                    'FaceAlpha', 0.5, 'EdgeColor', 'none');
                patch(obj.hAx3, [obj.hAx3.XLim(1),obj.hAx3.XLim(1),...
                    obj.hAx3.XLim(2),obj.hAx3.XLim(2)],[obj.hAx3.YLim(1),...
                    obj.hAx3.YLim(2),obj.hAx3.YLim(2),obj.hAx3.YLim(1)], ...
                    [1,1,1], ...
                    'FaceAlpha', 0.5, 'EdgeColor', 'none');
                
                if (~isempty(obj.vSignal_orig))
                    obj.hButton_File.Enable = 'off';
                    obj.hText_Message_BG.Visible = 'on';
                    obj.hText_Message.Visible = 'on';
                end
                
                obj.hText_Length.Enable = 'off';
                obj.hText_Blocklen.Enable = 'off';
                obj.hText_Base.Enable = 'off';
                obj.hText_P1.Enable = 'off';
                obj.hText_P2.Enable = 'off';
                obj.hText_tauFast.Enable = 'off';
                obj.hText_tauSlow.Enable = 'off';
                obj.hEdit_Length.Enable = 'off';
                obj.hEdit_Blocklen.Enable = 'off';
                obj.hButton_Left.Enable = 'off';
                obj.hButton_Right.Enable = 'off';
                obj.hButton_Max.Enable = 'off';
                obj.hButton_Min.Enable = 'off';
                obj.hButton_Home.Enable = 'off';
                obj.hEdit_Base_WB.Enable = 'off';
                obj.hEdit_Base_LP.Enable = 'off';
                obj.hEdit_Base_BP.Enable = 'off';
                obj.hEdit_Base_HP.Enable = 'off';
                obj.hEdit_P1_WB.Enable = 'off';
                obj.hEdit_P1_LP.Enable = 'off';
                obj.hEdit_P1_BP.Enable = 'off';
                obj.hEdit_P1_HP.Enable = 'off';
                obj.hEdit_P2_WB.Enable = 'off';
                obj.hEdit_P2_LP.Enable = 'off';
                obj.hEdit_P2_BP.Enable = 'off';
                obj.hEdit_P2_HP.Enable = 'off';
                obj.hEdit_tauFast_WB.Enable = 'off';
                obj.hEdit_tauFast_LP.Enable = 'off';
                obj.hEdit_tauFast_BP.Enable = 'off';
                obj.hEdit_tauFast_HP.Enable = 'off';
                obj.hEdit_tauSlow_WB.Enable = 'off';
                obj.hEdit_tauSlow_LP.Enable = 'off';
                obj.hEdit_tauSlow_BP.Enable = 'off';
                obj.hEdit_tauSlow_HP.Enable = 'off';
                
            end
            
            drawnow;
            
        end
        
        function [] = callbackOpen(obj, ~, ~)
            
            obj.setEditable(false)
            
            obj.nMagnification = 1;
            obj.vXLim_orig = [];
            obj.nTimeWindow = 10;
            obj.hEdit_Length.Value = num2str(obj.nTimeWindow);
            
            [tmp_file, tmp_path] = uigetfile({'*.wav;*.mp3'});
            
            if (tmp_file == 0)
                return;
            end
            
            obj.sFileName = tmp_file;
            obj.sPathName = tmp_path;
            obj.hText_File.Value = sprintf('%s', obj.sFileName);
            
            [obj.vSignal_orig, obj.nFs] = audioread(obj.sFileName);
            
            obj.hText_File.Tooltip = sprintf('%s', obj.sFileName);
            
            obj.cutAndFilter();
            obj.detectOnsets();
            obj.plotData();
            
            obj.setEditable(true)
            
        end
        
        function [] = cutAndFilter(obj, ~, ~)
            
            obj.setEditable(false)
            
            nLen_orig = length(obj.vSignal_orig)/obj.nFs;
            if (obj.nTimeWindow > nLen_orig)
                obj.nTimeWindow = nLen_orig;
                obj.hEdit_Length.Value = sprintf('%.2f', nLen_orig);
            end
            
            if (obj.nTimeWindow ~= 0 && obj.nTimeWindow <= length(obj.vSignal_orig)/obj.nFs)
                obj.vSignal = obj.vSignal_orig(1 : obj.nTimeWindow * obj.nFs, :);
            end
        
            obj.vXLim_orig = [0, obj.nTimeWindow];
            obj.vAusschnitt = obj.vXLim_orig;
            
            % Hi Pass filter signal
            nOrder_HP = 4;
            vFreq_HP = [0.01, 0.02];
            [vB, vA] = butter(nOrder_HP, vFreq_HP);
            obj.vSignal = filter(vB, vA, obj.vSignal);
            
            obj.setEditable(true)
 
        end
        
        function [] = callbackNoChange(obj, source, ~)
            
            switch source
               
                
            end
            
        end
        
        function [] = callbackValueChanging(obj, source, event)
           
            if (str2double(event.Value) < 0)
               source.Value = sprintf('0'); 
            end
            
        end
        
        function [] = callbackValueChanged(obj, source, event)
            
            switch source
                
                % Time window
                case obj.hEdit_Length
                    
                    if isnan(str2double(obj.hEdit_Length.Value))
                        obj.hEdit_Length.Value = sprintf('%.2f', obj.nTimeWindow);
                        return;
                    end
                    
                    obj.nTimeWindow = str2double(obj.hEdit_Length.Value);
                    obj.hEdit_Length.Value = sprintf('%.2f', obj.nTimeWindow);
                    
                    if isempty(obj.vSignal_orig)
                        return;
                    end
                    
                    obj.cutAndFilter();
                    % Block length
                case obj.hEdit_Blocklen
                    
                    if isnan(str2double(obj.hEdit_Blocklen.Value))
                        obj.hEdit_Length.Value = sprintf('%.2f', obj.nParameter_BlockSize);
                        return;
                    end
                    
                    obj.nParameter_BlockSize = str2double(obj.hEdit_Blocklen.Value);
                    obj.hEdit_Blocklen.Value = sprintf('%.d', obj.nParameter_BlockSize);
                    % Threshold base
                case obj.hEdit_Base_WB
                    obj.vParameter_ThreshBase(1) = str2double(obj.hEdit_Base_WB.Value);
                    obj.hEdit_Base_WB.Value = sprintf('%.2f', obj.vParameter_ThreshBase(1));
                case obj.hEdit_Base_LP
                    obj.vParameter_ThreshBase(2) = str2double(obj.hEdit_Base_LP.Value);
                    obj.hEdit_Base_LP.Value = sprintf('%.2f', obj.vParameter_ThreshBase(2));
                case obj.hEdit_Base_BP
                    obj.vParameter_ThreshBase(3) = str2double(obj.hEdit_Base_BP.Value);
                    obj.hEdit_Base_BP.Value = sprintf('%.2f', obj.vParameter_ThreshBase(3));
                case obj.hEdit_Base_HP
                    obj.vParameter_ThreshBase(4) = str2double(obj.hEdit_Base_HP.Value);
                    obj.hEdit_Base_HP.Value = sprintf('%.2f', obj.vParameter_ThreshBase(4));
                    % Parameter 1
                case obj.hEdit_P1_WB
                    obj.vParameter_1(1) = str2double(obj.hEdit_P1_WB.Value);
                    obj.hEdit_P1_WB.Value = sprintf('%.2f', obj.vParameter_1(1));
                case obj.hEdit_P1_LP
                    obj.vParameter_1(2) = str2double(obj.hEdit_P1_LP.Value);
                    obj.hEdit_P1_LP.Value = sprintf('%.2f', obj.vParameter_1(2));
                case obj.hEdit_P1_BP
                    obj.vParameter_1(3) = str2double(obj.hEdit_P1_BP.Value);
                    obj.hEdit_P1_BP.Value = sprintf('%.2f', obj.vParameter_1(3));
                case obj.hEdit_P1_HP
                    obj.vParameter_1(4) = str2double(obj.hEdit_P1_HP.Value);
                    obj.hEdit_P1_HP.Value = sprintf('%.2f', obj.vParameter_1(4));
                    % Parameter 2
                case obj.hEdit_P2_WB
                    obj.vParameter_2(1) = str2double(obj.hEdit_P2_WB.Value);
                    obj.hEdit_P2_WB.Value = sprintf('%.2f', obj.vParameter_2(1));
                case obj.hEdit_P2_LP
                    obj.vParameter_2(2) = str2double(obj.hEdit_P2_LP.Value);
                    obj.hEdit_P2_LP.Value = sprintf('%.2f', obj.vParameter_2(2));
                case obj.hEdit_P2_BP
                    obj.vParameter_2(3) = str2double(obj.hEdit_P2_BP.Value);
                    obj.hEdit_P2_BP.Value = sprintf('%.2f', obj.vParameter_2(3));
                case obj.hEdit_P2_HP
                    obj.vParameter_2(4) = str2double(obj.hEdit_P2_HP.Value);
                    obj.hEdit_P2_HP.Value = sprintf('%.2f', obj.vParameter_2(4));
                    % Tau Fast
                case obj.hEdit_tauFast_WB
                    obj.vParameter_TauFast(1) = str2double(obj.hEdit_tauFast_WB.Value);
                    obj.hEdit_tauFast_WB.Value = sprintf('%.2f', obj.vParameter_TauFast(1));
                case obj.hEdit_tauFast_LP
                    obj.vParameter_TauFast(2) = str2double(obj.hEdit_tauFast_LP.Value);
                    obj.hEdit_tauFast_LP.Value = sprintf('%.2f', obj.vParameter_TauFast(2));
                case obj.hEdit_tauFast_BP
                    obj.vParameter_TauFast(3) = str2double(obj.hEdit_tauFast_BP.Value);
                    obj.hEdit_tauFast_BP.Value = sprintf('%.2f', obj.vParameter_TauFast(3));
                case obj.hEdit_tauFast_HP
                    obj.vParameter_TauFast(4) = str2double(obj.hEdit_tauFast_HP.Value);
                    obj.hEdit_tauFast_HP.Value = sprintf('%.2f', obj.vParameter_TauFast(4));
                    % Tau Slow
                case obj.hEdit_tauSlow_WB
                    obj.vParameter_TauSlow(1) = str2double(obj.hEdit_tauSlow_WB.Value);
                    obj.hEdit_tauSlow_WB.Value = sprintf('%.2f', obj.vParameter_TauSlow(1));
                case obj.hEdit_tauSlow_LP
                    obj.vParameter_TauSlow(2) = str2double(obj.hEdit_tauSlow_LP.Value);
                    obj.hEdit_tauSlow_LP.Value = sprintf('%.2f', obj.vParameter_TauSlow(2));
                case obj.hEdit_tauSlow_BP
                    obj.vParameter_TauSlow(3) = str2double(obj.hEdit_tauSlow_BP.Value);
                    obj.hEdit_tauSlow_BP.Value = sprintf('%.2f', obj.vParameter_TauSlow(3));
                case obj.hEdit_tauSlow_HP
                    obj.vParameter_TauSlow(4) = str2double(obj.hEdit_tauSlow_HP.Value);
                    obj.hEdit_tauSlow_HP.Value = sprintf('%.2f', obj.vParameter_TauSlow(4));
                    
            end
            
            obj.detectOnsets();
            obj.plotData();
            
        end
        
        function [] = callbackMax(obj, ~, ~)
            
            obj.nMagnification = obj.nMagnification + 1;
            tmpDyn = diff(obj.hAx1.XLim);
            tmpMean = mean(obj.hAx1.XLim);
            tmpXLimNew = [tmpMean - 0.5*tmpDyn/obj.nMagFactor, tmpMean + 0.5*tmpDyn/obj.nMagFactor];
            
            obj.hAx1.XLim = tmpXLimNew;
            obj.hAx2.XLim = tmpXLimNew;
            obj.hAx3.XLim = tmpXLimNew;
            obj.vAusschnitt = tmpXLimNew;
            
        end
        
        function [] = callbackMin(obj, ~, ~)
            
            if (obj.nMagnification == 1)
                return;
            end
            
            obj.nMagnification = obj.nMagnification - 1;
            tmpDyn = diff(obj.hAx1.XLim);
            tmpMean = mean(obj.hAx1.XLim);
            tmpXLimNew = [tmpMean - obj.nMagFactor*0.5*tmpDyn, tmpMean + obj.nMagFactor*0.5*tmpDyn];
            
            % Respect min and max XLim
            if (tmpXLimNew(2) > obj.vXLim_orig(2))
                tmpXLimNew = [(obj.vXLim_orig(2) - obj.nMagFactor*tmpDyn), obj.vXLim_orig(2)];
            end
            
            if (tmpXLimNew(1) < obj.vXLim_orig(1))
                tmpXLimNew = [obj.vXLim_orig(1), obj.vXLim_orig(1) + tmpDyn * obj.nMagFactor];
            end
            
            obj.hAx1.XLim = tmpXLimNew;
            obj.hAx2.XLim = tmpXLimNew;
            obj.hAx3.XLim = tmpXLimNew;
            obj.vAusschnitt = tmpXLimNew;
            
        end
        
        function [] = callbackLeft(obj, ~, ~)
            
            tmpDyn = diff(obj.hAx1.XLim);
            tmpXLimNew = [obj.hAx1.XLim] - obj.nShiftFactor * tmpDyn;
            
            if (tmpXLimNew(1) < 0)
                tmpXLimNew = obj.hAx1.XLim - obj.hAx1.XLim(1);
            end
            
            obj.hAx1.XLim = tmpXLimNew;
            obj.hAx2.XLim = tmpXLimNew;
            obj.hAx3.XLim = tmpXLimNew;
            obj.vAusschnitt = tmpXLimNew;
            
        end
        
        
        function [] = callbackRight(obj, ~, ~)
            
            tmpDyn = diff(obj.hAx1.XLim);
            tmpXLimNew = [obj.hAx1.XLim] + obj.nShiftFactor * tmpDyn;
            
            nMax = obj.vXLim_orig(2);
            
            if (tmpXLimNew(2) > nMax)
                tmpXLimNew = [nMax - tmpDyn, nMax];
            end
            
            obj.hAx1.XLim = tmpXLimNew;
            obj.hAx2.XLim = tmpXLimNew;
            obj.hAx3.XLim = tmpXLimNew;
            obj.vAusschnitt = tmpXLimNew;
            
        end
        
        function [] = callbackHome(obj, ~, ~)
            
            obj.nMagnification = 1;
            obj.hAx1.XLim = obj.vXLim_orig;
            obj.hAx2.XLim = obj.vXLim_orig;
            obj.hAx3.XLim = obj.vXLim_orig;
            obj.vAusschnitt = obj.vXLim_orig;
            
        end
      
        function [] = detectOnsets(obj, ~, ~)
            
            obj.setEditable(false)
            
            obj.mThresh_hist = zeros(obj.nTimeWindow * obj.nFs, obj.nChannels);
            
            % INITIALISE FILTERS
            state1 = 0; state2 = 0;
            
            running = true;
            
            threshold_raise = [1, 1, 1, 1];
            
            obj.vPeakLoc = [];
            
            % while running
            nBlocks = floor(obj.nTimeWindow * obj.nFs / obj.nParameter_BlockSize);
            
            for iBlock = 1:nBlocks
                
                iIn = (iBlock - 1) * obj.nParameter_BlockSize + 1;
                iOut = iIn + obj.nParameter_BlockSize - 1;
                vBlockData = obj.vSignal(iIn:iOut);
                
                if ~ isempty(vBlockData)
                    
                    % bandsplit
                    [obj.vOut_LP, obj.vOut_BP, obj.vOut_HP, state1, state2] = ...
                        obj.SVF_bandsplit(vBlockData, obj.nFs, 800, 1/sqrt(2), state1, state2);
                    
                    % energy ratio
                    [obj.vEnergRatio_LP, obj.Zi_fast_lp, obj.Zi_slow_lp] = ...
                        obj.FastToSlowEnergyMeasure(obj.vOut_LP, obj.nFs, obj.vParameter_TauFast(1), obj.vParameter_TauSlow(1), obj.Zi_fast_lp, obj.Zi_slow_lp);
                    [obj.vEnergRatio_BP, obj.Zi_fast_bp, obj.Zi_slow_bp] = ...
                        obj.FastToSlowEnergyMeasure(obj.vOut_BP, obj.nFs, obj.vParameter_TauFast(2), obj.vParameter_TauSlow(2 ), obj.Zi_fast_bp, obj.Zi_slow_bp);
                    [obj.vEnergRatio_HP, obj.Zi_fast_hp, obj.Zi_slow_hp] = ...
                        obj.FastToSlowEnergyMeasure(obj.vOut_HP, obj.nFs, obj.vParameter_TauFast(3), obj.vParameter_TauSlow(3), obj.Zi_fast_hp, obj.Zi_slow_hp);
                    [obj.vEnergRatio_WB, obj.Zi_fast_wb, obj.Zi_slow_wb] = ...
                        obj.FastToSlowEnergyMeasure(vBlockData, obj.nFs, obj.vParameter_TauFast(4), obj.vParameter_TauSlow(4), obj.Zi_fast_wb, obj.Zi_slow_wb);
                    
                    DataMatrix = [obj.vEnergRatio_LP, ...
                        obj.vEnergRatio_BP, ...
                        obj.vEnergRatio_HP, ...
                        obj.vEnergRatio_WB];
                    
                    for kk = 1 : obj.nParameter_BlockSize
                        
                        threshold = obj.vParameter_ThreshBase + threshold_raise;
                        flags = DataMatrix(kk, :) > threshold;
                        
                        obj.mThresh_hist(iIn + kk - 1, :) = threshold;

                        %  check for transients
                        if sum(flags) >= 1
                            obj.vPeakLoc(end+1) = ((iBlock - 1) * obj.nParameter_BlockSize  + kk) / obj.nFs;
                            threshold_raise = obj.vParameter_1 .* threshold;
                        end
                        threshold_raise = threshold_raise .* obj.vParameter_2;
                    end
                    
                else
                    break
                end
                
            end
            
            obj.setEditable(true)
            
        end
        
        function [] = plotData(obj, ~, ~)
            
            obj.setEditable(false)
            
            SampleVec = (1 : obj.nTimeWindow * obj.nFs) / obj.nFs;
            
            % bandsplit
            [obj.vOut_LP, obj.vOut_BP, obj.vOut_HP, ~, ~] = ...
                obj.SVF_bandsplit(obj.vSignal, obj.nFs, 800, 1/sqrt(2), 0, 0);
            
            
            [obj.vEnergRatio_WB, ~, ~] = ...
                obj.FastToSlowEnergyMeasure(obj.vSignal, obj.nFs, obj.vParameter_TauFast(1), obj.vParameter_TauSlow(1), 0, 0);
            [obj.vEnergRatio_LP, ~, ~] = ...
                obj.FastToSlowEnergyMeasure(obj.vOut_LP, obj.nFs, obj.vParameter_TauFast(2), obj.vParameter_TauSlow(2), 0, 0);
            [obj.vEnergRatio_BP, ~, ~] = ...
                obj.FastToSlowEnergyMeasure(obj.vOut_BP, obj.nFs, obj.vParameter_TauFast(3), obj.vParameter_TauSlow(3), 0, 0);
            [obj.vEnergRatio_HP, ~, ~] = ...
                obj.FastToSlowEnergyMeasure(obj.vOut_HP, obj.nFs, obj.vParameter_TauFast(4), obj.vParameter_TauSlow(4), 0, 0);
            
            % Top Plot: Wideband Signal
            obj.hAx1.NextPlot = 'replace';
            plot(obj.hAx1, SampleVec, obj.vSignal / max(abs(obj.vSignal)));
            obj.hAx1.NextPlot = 'add';
            for iPeak = obj.vPeakLoc
                plot(obj.hAx1, iPeak * [1, 1], [-1; 1], 'Color', obj.vColor_Marker, ...
                    'LineStyle', ':');
            end
            obj.hAx1.Box = 'on';
            obj.hAx1.YTick = [];
            obj.hAx1.XTick = [];
            
            obj.hAx1.XLim = obj.vAusschnitt;
            
            obj.hAx1.YLim = [-1, 1];
            obj.hAx1.YLabel.String = 'Wideband Signal';
            
            tmp_Children = get(obj.hAx1, 'Children');
            for iChild = 1:length(tmp_Children)
                tmp_Children(iChild).HitTest = 'off';
            end
            
            % Middle Plot: Energy Levels
            obj.hAx2.NextPlot = 'replace';
            plot(obj.hAx2, SampleVec,obj.vEnergRatio_WB , 'Color', obj.mColor(1, :));
            obj.hAx2.NextPlot = 'add';
            plot(obj.hAx2, SampleVec, obj.vEnergRatio_LP + 10, 'Color', obj.mColor(2, :));
            plot(obj.hAx2, SampleVec, obj.vEnergRatio_BP + 20, 'Color', obj.mColor(3, :));
            plot(obj.hAx2, SampleVec,obj.vEnergRatio_HP + 30, 'Color', obj.mColor(4, :));
            
            for iPeak = obj.vPeakLoc
                plot(obj.hAx2, iPeak * [1, 1], [0; 40], 'Color', obj.vColor_Marker, ...
                    'LineStyle', ':');
            end
            obj.hAx2.Box = 'on';
            obj.hAx2.YTick = [];
            obj.hAx2.XTick = [];
            obj.hAx2.XLim = obj.vAusschnitt;
            
            obj.hAx2.YLim = [0, 40];
            obj.hAx2.YLabel.String = 'Energy Levels';
            
            tmp_Children = get(obj.hAx2, 'Children');
            for iChild = 1:length(tmp_Children)
                tmp_Children(iChild).HitTest = 'off';
            end
            
            % Bottom Plot: Dynamic Thresholds
            obj.hAx3.NextPlot = 'replace';
            plot(obj.hAx3, SampleVec, obj.mThresh_hist);
            obj.hAx3.NextPlot = 'add';
            for iPeak = obj.vPeakLoc
                plot(obj.hAx3, iPeak * [1, 1], obj.hAx3.YLim, 'Color', obj.vColor_Marker, ...
                    'LineStyle', ':');
            end
            obj.hAx3.Box = 'on';
            obj.hAx3.YTick = [];
            obj.hAx3.XLim = obj.vAusschnitt;
            obj.hAx3.YLabel.String = 'Dynamic Thresholds';
            
            tmp_Children = get(obj.hAx3, 'Children');
            for iChild = 1:length(tmp_Children)
                tmp_Children(iChild).HitTest = 'off';
            end
            
            disableDefaultInteractivity(obj.hAx1)
            disableDefaultInteractivity(obj.hAx2)
            disableDefaultInteractivity(obj.hAx3)
           
            obj.setEditable(true)
            
        end
        
        function [EnergRatio, Zf_fast, Zf_slow] = ...
                FastToSlowEnergyMeasure(obj, inSig, fs, tau_fast_ms, tau_slow_ms, Zi_fast, Zi_slow)
            
            % params:
            %           inSig: onedimensional input signal
            %           fs: sampling rate
            %           tau_fast_ms/tau_slow_ms: time weighting in ms
            %           Zi_fast/Zi_slow: filter states (used for repeatedly use of
            %                           this function by feeding back Zf_fast/Zf_slow)
            %
            % outputs:
            %           EnergRatio: fast RMS signal divided by slow RMS signal
            %           Zf_fast/Zf_slow: filter states post filtering
            
            if nargin < 6
                Zi_slow = 0;
            end
            
            if nargin < 5
                Zi_fast = 0;
            end
            
            if nargin < 4
                tau_slow_ms = 5;
            end
            
            if nargin < 3
                tau_fast_ms = 1;
            end
            
            RMS_alpha_fast = exp(-1/(tau_fast_ms*0.001*fs));
            RMS_alpha_slow = exp(-1/(tau_slow_ms*0.001*fs));
            
            [y1,Zf_fast] = filter([1-RMS_alpha_fast],[1 -RMS_alpha_fast],inSig.*inSig,Zi_fast);
            [y2,Zf_slow] = filter([1-RMS_alpha_slow],[1 -RMS_alpha_slow],inSig.*inSig,Zi_slow);
            
            EnergRatio = y1./y2;
            
        end
        
        function [out_lp, out_bp, out_hp, state1new, state2new] = ...
                SVF_bandsplit(obj, inSig, fs, cutoff, Q, state1, state2)
            % implments a state varable filter with a given cutoff and Q
            % USAGE: [out_lp, out_bp,out_hp] = SVF_bandsplit(inSig,fs,cutoff,Q)
            % params:
            %       inSig: input signal of dimension len x 1 (must be onedim)
            %       fs: samplingrate
            %       cutoff: cutoff frequency for high, low and bandpass (mid freq)
            %       Q: Q factor (default = 1/sqrt(2) = Butterworth)
            %
            % Sources
            % https://ccrma.stanford.edu/~jos/svf/svf.pdf
            % https://github.com/JordanTHarris/VAStateVariableFilter/blob/master/Source/Effects/VAStateVariableFilter.cpp
            
            % J. Bitzer
            % BSD 3 clause license is applied
            % Version 1.0  Aug 2019
            
            if nargin < 6
                state2 = 0;
            end
            
            if nargin < 5
                state1 = 0;
            end
            
            if nargin < 4
                Q = 1/sqrt(2);
            end
            wd = cutoff * 2.0 * pi;
            T = 1.0 / fs;
            wa = (2.0 / T) * tan(wd * T / 2.0);
            
            gCoeff = wa * T / 2.0;
            RCoeff = 1.0 / (2.0 * Q);
            
            
            Mul_state1 = 2*RCoeff+gCoeff;
            Mul_in = 1/(1+ 2*RCoeff*gCoeff + gCoeff*gCoeff);
            
            out_lp = zeros(size(inSig));
            out_bp = zeros(size(inSig));
            out_hp = zeros(size(inSig));
            
            for kk = 1:length(inSig)
                in = inSig(kk);
                
                yhp = (in-Mul_state1*state1 - state2)*Mul_in;
                
                help1 = yhp*gCoeff;
                
                ybp = state1 + help1;
                
                state1 = ybp + help1;
                
                help2 = ybp*gCoeff;
                
                ylp = state2 + help2;
                
                state2 = ylp + help2;
                
                out_lp(kk) = ylp;
                out_bp(kk) = ybp;
                out_hp(kk) = yhp;
                
                state1new = state1;
                state2new = state2;
            end
        end
        
        
        
    end
    
    
    
    
    
end