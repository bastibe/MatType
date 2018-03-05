classdef MatType < handle
    properties
        Figure
        TemplateCharacters
        TypingCharacters
        xMargin = 10
        yMargin = 10
        charWidth = 7
        charHeight = 12
        cursorIdx
    end
    methods
        function obj = MatType(defaultText)
            if ~exist('defaultText') || isempty(defaultText)
                templateText = 'lorem ipsum dolor sit amet';
            else
                templateText = defaultText;
            end

            obj.Figure = figure();
            obj.CreateCharacters(templateText);
            obj.cursorIdx = 1;

            obj.Figure.KeyPressFcn = @obj.KeyPress;

        end
        function KeyPress(obj, handle, event)
            c = event.Character;
            if obj.cursorIdx > length(obj.TemplateCharacters)
                return
            elseif c >= ' ' && c <= '~'
                typingCharacter = obj.TypingCharacters(obj.cursorIdx);
                typingCharacter.String = c;
                templateCharacter = obj.TemplateCharacters(obj.cursorIdx);
                if templateCharacter.String == typingCharacter.String
                    templateCharacter.ForegroundColor = [0 1 0];
                else
                    templateCharacter.ForegroundColor = [1 0 0];
                end
                obj.cursorIdx = obj.cursorIdx + 1;
            elseif strcmp(event.Key, 'backspace') && obj.cursorIdx > 1
                obj.cursorIdx = obj.cursorIdx - 1;
                templateCharacter = obj.TemplateCharacters(obj.cursorIdx);
                templateCharacter.ForegroundColor = [0 0 0];
                typingCharacter = obj.TypingCharacters(obj.cursorIdx);
                typingCharacter.String = ' ';
            end
        end

        function CreateCharacters(obj, text)
            figSize = obj.Figure.Position(3:4);
            xPos = obj.yMargin;
            yPos = figSize(2) - obj.yMargin - obj.charHeight;
            for idx=1:length(text)
                character = uicontrol('style', 'text');
                character.Position = ...
                    [xPos, yPos, obj.charWidth, obj.charHeight+2];
                character.FontName = 'FixedWidth';
                character.FontUnits = 'pixels';
                character.FontSize = obj.charHeight;
                character.String = text(idx);
                obj.TemplateCharacters = [obj.TemplateCharacters character];

                character = uicontrol('style', 'text');
                character.Position = ...
                    [xPos, yPos-figSize(2)/2, obj.charWidth, obj.charHeight+2];
                character.FontName = 'FixedWidth';
                character.FontUnits = 'pixels';
                character.FontSize = obj.charHeight;
                character.String = 'X';
                obj.TypingCharacters = [obj.TypingCharacters character];

                if (xPos + obj.charWidth + 1) > (figSize(1) - obj.xMargin)
                    xPos = obj.xMargin;
                    yPos = yPos - obj.charHeight + 2;
                else
                    xPos = xPos + obj.charWidth + 1;
                end
            end
        end
    end
end
