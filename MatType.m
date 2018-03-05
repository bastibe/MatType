classdef MatType < handle
    properties
        Figure
        TemplateCharacters
        TypingCharacters
        CursorIdx
        XMargin = 10
        YMargin = 10
        CharWidth = 7
        CharHeight = 12

    end
    methods
        function obj = MatType(defaultText)
            obj.Figure = figure();
            obj.Figure.MenuBar = 'none';
            obj.Figure.ToolBar = 'none';
            obj.Figure.Resize = 'off';
            obj.Figure.Name = 'MatType';
            obj.Figure.NumberTitle = 'off';
            obj.Figure.KeyPressFcn = @obj.KeyPress;

            if ~exist('defaultText') || isempty(defaultText)
                templateText = 'lorem ipsum dolor sit amet';
            else
                templateText = defaultText;
            end
            obj.CreateCharacters(templateText);

            obj.CursorIdx = 1;
        end

        function KeyPress(obj, handle, event)
            c = event.Character;
            if obj.CursorIdx > length(obj.TemplateCharacters)
                return
            elseif c >= ' ' && c <= '~'
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
    end
end
