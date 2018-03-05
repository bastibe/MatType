classdef MatType < handle
    properties
        Figure
        TemplateCharacters
        TypingCharacters
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
            obj.Figure = figure();
            obj.Figure.MenuBar = 'none';
            obj.Figure.ToolBar = 'none';
            obj.Figure.Resize = 'off';
            obj.Figure.Name = 'MatType';
            obj.Figure.NumberTitle = 'off';
            obj.Figure.WindowKeyPressFcn = @obj.KeyPress;

            if ~exist('defaultText') || isempty(defaultText)
                templateText = 'lorem ipsum dolor sit amet';
            else
                templateText = defaultText;
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
            c = event.Character;
            if ~isempty(c) && c >= ' ' && c <= '~'
                typingCharacter = obj.TypingCharacters(obj.CursorIdx);
                typingCharacter.String = c;
                templateCharacter = obj.TemplateCharacters(obj.CursorIdx);
                if templateCharacter.String == typingCharacter.String
                    templateCharacter.ForegroundColor = [0 1 0];
                else
                    templateCharacter.ForegroundColor = [1 0 0];
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

        function CreateCharacters(obj, text)
            figSize = obj.Figure.Position(3:4);
            xPos = obj.XMargin;
            yPos = figSize(2) - obj.YMargin - obj.CharHeight;
            for idx=1:length(text)
                character = uicontrol('style', 'text');
                character.Position = ...
                    [xPos, yPos, obj.CharWidth, obj.CharHeight+2];
                character.FontName = 'FixedWidth';
                character.FontUnits = 'pixels';
                character.FontSize = obj.CharHeight;
                character.String = text(idx);
                obj.TemplateCharacters = [obj.TemplateCharacters character];

                character = uicontrol('style', 'text');
                character.Position = ...
                    [xPos, yPos-figSize(2)/2, obj.CharWidth, obj.CharHeight+2];
                character.FontName = 'FixedWidth';
                character.FontUnits = 'pixels';
                character.FontSize = obj.CharHeight;
                character.String = 'X';
                obj.TypingCharacters = [obj.TypingCharacters character];

                if (xPos + obj.CharWidth + 1) > (figSize(1) - obj.XMargin)
                    xPos = obj.XMargin;
                    yPos = yPos - obj.CharHeight + 2;
                else
                    xPos = xPos + obj.CharWidth + 1;
                end
            end
        end

        function DrawCursor(obj, handle, event)
            character = obj.TypingCharacters(obj.CursorIdx);
            if character.BackgroundColor == obj.Figure.Color
                character.BackgroundColor = [0 0 0];
                character.ForegroundColor = [1 1 1];
            else
                character.BackgroundColor = obj.Figure.Color;
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
    end
end
