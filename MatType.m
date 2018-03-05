classdef MatType < handle
    properties
        Figure
        TemplateCharacters = matlab.ui.control.UIControl
        TypingCharacters = matlab.ui.control.UIControl
        TypingBackground
        CursorTimer
        TrueCursorIdx = 1
        XMargin = 10
        YMargin = 10
        CharWidth = 7
        CharHeight = 12
    end

    properties (Dependent)
        CursorIdx
    end

    methods
        function obj = MatType(defaultText)
            % Force Matlab to use UTF-8 if possible
            if exist('slCharacterEncoding') && ...
               ~strcmp(feature('DefaultCharacterSet'), 'UTF-8')
                slCharacterEncoding('UTF8');
            end

            obj.Figure = figure();
            obj.Figure.MenuBar = 'none';
            obj.Figure.ToolBar = 'none';
            obj.Figure.Resize = 'off';
            obj.Figure.Name = 'MatType - Typing Tutor';
            obj.Figure.NumberTitle = 'off';
            obj.Figure.WindowKeyPressFcn = @obj.KeyPress;
            figsize = obj.Figure.Position(3:4);

            obj.TypingBackground = uicontrol('style', 'text');
            obj.TypingBackground.Position = ...
                [obj.XMargin obj.YMargin ...
                 figsize(1)-2*obj.XMargin, figsize(2)/2-2*obj.YMargin+2];
            obj.TypingBackground.BackgroundColor = [1 1 1];

            if ~exist('defaultText') || isempty(defaultText)
                templateText = obj.DefaultText();
            else
                templateText = text;
            end
            obj.CreateCharacters(templateText);

            obj.CursorIdx = 1;
            obj.CursorTimer = timer();
            obj.CursorTimer.ExecutionMode = 'FixedRate';
            obj.CursorTimer.Period = 0.5;
            obj.CursorTimer.TimerFcn = @obj.DrawCursor;
            start(obj.CursorTimer);
            obj.Figure.DeleteFcn = @obj.DeleteCursorTimer;
        end

        function KeyPress(obj, handle, event)
            c = obj.Character2letter(event.Character);
            if c && obj.CursorIdx < length(obj.TypingCharacters)
                typingCharacter = obj.TypingCharacters(obj.CursorIdx);
                typingCharacter.String = c;
                templateCharacter = obj.TemplateCharacters(obj.CursorIdx);
                if templateCharacter.String == typingCharacter.String
                    templateCharacter.ForegroundColor = [0 0.6 0]; % green
                else
                    templateCharacter.ForegroundColor = [0.6 0 0]; % red
                end
                obj.CursorIdx = obj.CursorIdx + 1;
            elseif strcmp(event.Key, 'backspace') && obj.CursorIdx > 1
                obj.CursorIdx = obj.CursorIdx - 1;
                templateCharacter = obj.TemplateCharacters(obj.CursorIdx);
                templateCharacter.ForegroundColor = [0 0 0];
                typingCharacter = obj.TypingCharacters(obj.CursorIdx);
                typingCharacter.String = ' ';
            end
        end

        function letter = Character2letter(obj, c)
            % fixes German special characters
            if isempty(c)
                letter = false;
            elseif c >= ' ' && c <= '~'
                letter = c;
            elseif c == 65508
                letter = 'ä';
            elseif c == 65526
                letter = 'ö';
            elseif c == 65532
                letter = 'ü';
            elseif c == 65503
                letter = 'ß';
            elseif c == 65476
                letter = 'Ä';
            elseif c == 65494
                letter = 'Ö';
            elseif c == 65500
                letter = 'Ü';
            else
                letter = false;
            end
        end

        function CreateCharacters(obj, text)
            figSize = obj.Figure.Position(3:4);
            xPos = obj.XMargin;
            yPos = figSize(2) - obj.YMargin - obj.CharHeight;
            lineWidth = floor((figSize(1)-2*obj.XMargin) / (obj.CharWidth+1));
            lines = obj.LineBreak(text, lineWidth);
            idx = 1;
            for row=1:length(lines)
                line = lines{row};
                for col=1:length(line)
                    TemplateCharacter = uicontrol('style', 'text');
                    TemplateCharacter.Position = ...
                        [xPos, yPos, obj.CharWidth, obj.CharHeight+2];
                    TemplateCharacter.FontName = 'FixedWidth';
                    TemplateCharacter.FontUnits = 'pixels';
                    TemplateCharacter.FontSize = obj.CharHeight;
                    TemplateCharacter.String = line(col);
                    obj.TemplateCharacters(idx) = TemplateCharacter;

                    TypingCharacter = uicontrol('style', 'text');
                    TypingCharacter.Position = ...
                        [xPos, yPos-figSize(2)/2, obj.CharWidth, obj.CharHeight+2];
                    TypingCharacter.FontName = 'FixedWidth';
                    TypingCharacter.FontUnits = 'pixels';
                    TypingCharacter.FontSize = obj.CharHeight;
                    TypingCharacter.String = ' ';
                    TypingCharacter.BackgroundColor = [1 1 1];
                    obj.TypingCharacters(idx) = TypingCharacter;
                    xPos = xPos + obj.CharWidth + 1;
                    idx = idx + 1;
                end
                xPos = obj.XMargin;
                yPos = yPos - obj.CharHeight - 2;
            end
        end

        function lines = LineBreak(obj, text, maxLineLength)
            words = strsplit(text);
            lines = {};
            line = '';
            for idx=1:length(words)
                if length(line) == 0
                    line = words{idx};
                elseif length(line) + length(words{idx}) < maxLineLength
                    line = [line ' ' words{idx}];
                else
                    lines = [lines [line ' ']];
                    line = words{idx};
                end
            end
            lines = [lines line];
        end

        function DrawCursor(obj, handle, event)
            character = obj.TypingCharacters(obj.CursorIdx);
            if character.BackgroundColor == [1 1 1]
                character.BackgroundColor = [0 0 0];
                character.ForegroundColor = [1 1 1];
            else
                character.BackgroundColor = [1 1 1];
                character.ForegroundColor = [0 0 0];
            end
        end

        function DeleteCursorTimer(obj, handle, event)
            stop(obj.CursorTimer);
            delete(obj.CursorTimer);
        end

        function value = get.CursorIdx(obj)
            value = obj.TrueCursorIdx;
        end

        function obj = set.CursorIdx(obj, newCursorIdx)
            if newCursorIdx > length(obj.TypingCharacters)
                return
            end
            oldCharacter = obj.TypingCharacters(obj.TrueCursorIdx);
            newCharacter = obj.TypingCharacters(newCursorIdx);
            originalBackgroundColor = newCharacter.BackgroundColor;
            originalForegroundColor = newCharacter.ForegroundColor;
            newCharacter.BackgroundColor = oldCharacter.BackgroundColor;
            newCharacter.ForegroundColor = oldCharacter.ForegroundColor;
            oldCharacter.BackgroundColor = originalBackgroundColor;
            oldCharacter.ForegroundColor = originalForegroundColor;
            obj.TrueCursorIdx = newCursorIdx;
        end

        function text = DefaultText(obj)
            text = 'Einst stritten sich Nordwind und Sonne, wer von ihnen beiden wohl der Stärkere wäre, als ein Wanderer, der in einen warmen Mantel gehüllt war, des Weges daherkam. Sie wurden einig, daß derjenige für den Stärkeren gelten sollte, der den Wanderer zwingen würde, seinen Mantel abzunehmen. Der Nordwind blies mit aller Macht, aber je mehr er blies, desto fester hüllte sich der Wanderer in seinen Mantel ein. Endlich gab der Nordwind den Kampf auf. Nun erwärmte die Sonne die Luft mit ihren freundlichen Strahlen, und schon nach wenigen Augenblicken zog der Wanderer seinen Mantel aus. Da mußte der Nordwind zugeben, daß die Sonne von ihnen beiden der Stärkere war.';
        end
    end
end
