classdef MatType < handle
    % MatType tests your typing speed
    %
    % MatType will show you a text, and ask you to type it out for one
    % minute. After one minute, it will count how many words you typed
    % correctly, and display your words per minute.
    %
    % You can supply your own text with MatType(text).

    % Copyright (C) 2018 Bastian Bechtold
    %
    % This program is free software: you can redistribute it and/or
    % modify it under the terms of the GNU General Public License as
    % published by the Free Software Foundation, either version 3 of
    % the License, or (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % For the full text of the GNU General Public License, see
    % <https://www.gnu.org/licenses/>.

    properties
        % UI components:
        Figure
        TypingBackground
        AnnouncementPanel
        CountdownPanel
        % These need the type information to force them to be object
        % arrays instead of double arrays:
        TemplateCharacters = matlab.ui.control.UIControl
        TypingCharacters = matlab.ui.control.UIControl
        % Timers:
        CursorTimer            % Blinks the cursor
        CountdownTimer         % Updates the countdown
        % Layout:
        XMargin = 10           % Left and right margin
        YMargin = 10           % Top and bottom margin
        CharWidth = 7          % Width of a single char
        CharPadding = 1        % Padding between chars
        LineHeight = 12        % Height of each line
        LinePadding = 2        % Padding between lines
        % Countdown:
        CountdownStart = 0     % Countdown start time
        CountdownLength = 60   % Length of countdown in s
    end

    properties (Dependent)
        CursorIdx              % Current cursor position
    end

    properties (Hidden)
        TrueCursorIdx = 1      % Backend store for CursorIdx
    end

    methods
        function obj = MatType(defaultText)
            % Set up GUI and timers

            % Set up window:
            obj.Figure = figure();
            obj.Figure.MenuBar = 'none';
            obj.Figure.ToolBar = 'none';
            obj.Figure.Resize = 'off';
            obj.Figure.Name = 'MatType - Typing Tutor';
            obj.Figure.NumberTitle = 'off';
            obj.Figure.WindowKeyPressFcn = @obj.KeyPressCallback;
            figsize = obj.Figure.Position(3:4);

            % Set up a white background for the typing area:
            obj.TypingBackground = uicontrol('style', 'text');
            obj.TypingBackground.Position = ...
                [obj.XMargin obj.YMargin ...
                 figsize(1)-2*obj.XMargin, figsize(2)/2-2*obj.YMargin+2];
            obj.TypingBackground.BackgroundColor = [1 1 1];

            % Set up template text:
            if ~exist('defaultText') || isempty(defaultText)
                templateText = obj.DefaultText();
            else
                templateText = text;
            end
            obj.CreateCharacters(templateText);

            % Set up blinking cursor:
            obj.CursorIdx = 1;
            obj.CursorTimer = timer();
            obj.CursorTimer.ExecutionMode = 'FixedRate';
            obj.CursorTimer.Period = 0.5;
            obj.CursorTimer.TimerFcn = @obj.CursorCallback;
            start(obj.CursorTimer);
            obj.Figure.DeleteFcn = @obj.DeleteTimers;

            % Set up message area:
            obj.AnnouncementPanel = uicontrol('style', 'text');
            obj.AnnouncementPanel.Position = ...
                [figsize(1)/2-100 figsize(2)/4-25 200 50];
            obj.AnnouncementPanel.String = 'Start Typing';
            obj.AnnouncementPanel.FontUnits = 'pixels';
            obj.AnnouncementPanel.FontSize = 36;
            obj.AnnouncementPanel.ForegroundColor = [1 0 0];
            obj.AnnouncementPanel.BackgroundColor = [1 1 1];

            % Set up countdown area:
            obj.CountdownPanel = uicontrol('style', 'text');
            obj.CountdownPanel.Position = ...
                [figsize(1)/2-50 figsize(2)/2+5 100, 16];
            obj.CountdownPanel.String = obj.FormatCountdown(obj.CountdownLength);
            obj.CountdownPanel.FontUnits = 'pixels';
            obj.CountdownPanel.FontSize = 14;

            % Set up countdown timer:
            obj.CountdownTimer = timer();
            obj.CountdownTimer.ExecutionMode = 'FixedRate';
            obj.CountdownTimer.Period = 0.1;
            obj.CountdownTimer.TimerFcn = @obj.CountdownCallback;
        end

        function KeyPressCallback(obj, handle, event)
            % Type letter when keyboard key was pressed

            % Don't type after countdown finished:
            if obj.CountdownStart == -1
                return
            end

            letter = obj.Character2letter(event.Character);
            if letter && obj.CursorIdx < length(obj.TypingCharacters)
                if obj.CountdownStart == 0
                    obj.StartTyping();
                end
                currentCharacter = obj.TypingCharacters(obj.CursorIdx);
                currentCharacter.String = letter;
                templateCharacter = obj.TemplateCharacters(obj.CursorIdx);
                if templateCharacter.String == currentCharacter.String
                    templateCharacter.ForegroundColor = [0 0.6 0]; % green
                else
                    templateCharacter.ForegroundColor = [0.6 0 0]; % red
                end
                obj.CursorIdx = obj.CursorIdx + 1;
            elseif strcmp(event.Key, 'backspace') && obj.CursorIdx > 1
                obj.CursorIdx = obj.CursorIdx - 1;
                templateCharacter = obj.TemplateCharacters(obj.CursorIdx);
                templateCharacter.ForegroundColor = [0 0 0];
                currentCharacter = obj.TypingCharacters(obj.CursorIdx);
                currentCharacter.String = ' ';
            end
        end

        function letter = Character2letter(obj, c)
            % Fix German special characters (Matlab bug)
            if isempty(c) || c < ' '
                letter = false; % not a character
            elseif c >= ' ' && c <= '~'
                letter = c;
            else % Matlab-Bug: Non-ASCII characters are broken
                letter = char(typecast(uint16(c), 'uint8'));
                letter = letter(1);
            end
        end

        function CreateCharacters(obj, text)
            % Set up template and typing text areas

            % Both text areas are made of one `text` uicontrol per
            % character. This is the only way of controlling the color
            % of each individual character, and making sure that the
            % layout of template area and typing area is exactly the
            % same.
            figSize = obj.Figure.Position(3:4);
            xPos = obj.XMargin;
            yPos = figSize(2) - obj.YMargin - obj.LineHeight;
            lineWidth = floor((figSize(1)-2*obj.XMargin) / ...
                              (obj.CharWidth+obj.CharPadding));
            lines = obj.LineBreak(text, lineWidth);
            idx = 1;
            for row=1:length(lines)
                line = lines{row};
                for col=1:length(line)
                    TemplateCharacter = uicontrol('style', 'text');
                    TemplateCharacter.Position = ...
                        [xPos, yPos, ...
                         obj.CharWidth, obj.LineHeight+obj.LinePadding];
                    TemplateCharacter.FontName = 'FixedWidth';
                    TemplateCharacter.FontUnits = 'pixels';
                    TemplateCharacter.FontSize = obj.LineHeight;
                    TemplateCharacter.String = line(col);
                    obj.TemplateCharacters(idx) = TemplateCharacter;

                    TypingCharacter = uicontrol('style', 'text');
                    TypingCharacter.Position = ...
                        [xPos, yPos-figSize(2)/2, ...
                         obj.CharWidth, obj.LineHeight+obj.LinePadding];
                    TypingCharacter.FontName = 'FixedWidth';
                    TypingCharacter.FontUnits = 'pixels';
                    TypingCharacter.FontSize = obj.LineHeight;
                    TypingCharacter.String = ' ';
                    TypingCharacter.BackgroundColor = [1 1 1]; % white
                    obj.TypingCharacters(idx) = TypingCharacter;

                    xPos = xPos + obj.CharWidth + obj.CharPadding;
                    idx = idx + 1;
                end
                xPos = obj.XMargin;
                yPos = yPos - obj.LineHeight - obj.LinePadding;
            end
        end

        function lines = LineBreak(obj, text, maxLineLength)
            % Break text into lines of length < maxLineLength
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

        function StartTyping(obj)
            % Clear typing area and start countdown
            for character=obj.TypingCharacters
                character.String = ' ';
            end
            obj.CursorIdx = 1;
            obj.AnnouncementPanel.Visible = 'off';
            obj.CountdownStart = tic();
            start(obj.CountdownTimer);
        end

        function StopTyping(obj)
            % Stop countdown and show score
            stop(obj.CountdownTimer);
            wpm = obj.CalculateScore();
            obj.CountdownStart = -1;
            obj.AnnouncementPanel.String = sprintf('%3.2f WPM', wpm);
            obj.AnnouncementPanel.Visible = 'on';
            obj.CountdownPanel.String = obj.FormatCountdown(0);
        end

        function CursorCallback(obj, handle, event)
            % Blink cursor (black on white or white on black)
            character = obj.TypingCharacters(obj.CursorIdx);
            if character.BackgroundColor == [1 1 1]
                character.BackgroundColor = [0 0 0]; % black
                character.ForegroundColor = [1 1 1]; % white
            else
                character.BackgroundColor = [1 1 1]; % white
                character.ForegroundColor = [0 0 0]; % black
            end
        end

        function CountdownCallback(obj, handle, event)
            % Update countdown text label
            remaining = obj.CountdownLength - toc(obj.CountdownStart);
            if remaining < 0
                obj.StopTyping();
            end
            obj.CountdownPanel.String = obj.FormatCountdown(remaining);
        end

        function str = FormatCountdown(obj, remainingSeconds)
            % Format remainingSeconds as countdown string
            if remainingSeconds < 0
                remainingSeconds = 0;
            end
            minutes = floor(remainingSeconds / 60);
            seconds = remainingSeconds - minutes*60;
            str = sprintf('%i:%04.1f s', minutes, seconds);
        end

        function wordsPerMinute = CalculateScore(obj)
            % Calculate correctly typed words per minute
            templateString = '';
            for character=obj.TemplateCharacters
                templateString = [templateString character.String];
            end
            typedString = '';
            for character=obj.TypingCharacters
                typedString = [typedString character.String];
            end
            correctWords = 0;
            wordCorrect = true;
            for idx=1:length(typedString)
                if templateString(idx) == ' '
                    if wordCorrect
                        correctWords = correctWords + 1;
                    end
                    wordCorrect = true;
                end
                wordCorrect = wordCorrect && ...
                              templateString(idx) == typedString(idx);
            end
            if wordCorrect
                correctWords = correctWords + 1;
            end

            wordsPerMinute = correctWords/(obj.CountdownLength/60);
        end

        function DeleteTimers(obj, handle, event)
            % Stop and delete all timers
            stop(obj.CursorTimer);
            delete(obj.CursorTimer);
            stop(obj.CountdownTimer);
            delete(obj.CountdownTimer);
        end

        function value = get.CursorIdx(obj)
            value = obj.TrueCursorIdx;
        end

        function obj = set.CursorIdx(obj, newCursorIdx)
            if newCursorIdx > length(obj.TypingCharacters) || ...
               newCursorIdx < 1
                return
            end
            % copy text style from old character to new character and
            % vice versa:
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
            % A default text (in German)
            text = 'Einst stritten sich Nordwind und Sonne, wer von ihnen beiden wohl der Stärkere wäre, als ein Wanderer, der in einen warmen Mantel gehüllt war, des Weges daherkam. Sie wurden einig, daß derjenige für den Stärkeren gelten sollte, der den Wanderer zwingen würde, seinen Mantel abzunehmen. Der Nordwind blies mit aller Macht, aber je mehr er blies, desto fester hüllte sich der Wanderer in seinen Mantel ein. Endlich gab der Nordwind den Kampf auf. Nun erwärmte die Sonne die Luft mit ihren freundlichen Strahlen, und schon nach wenigen Augenblicken zog der Wanderer seinen Mantel aus. Da mußte der Nordwind zugeben, daß die Sonne von ihnen beiden der Stärkere war.';
            text = native2unicode(unicode2native(text), 'UTF-8');
        end
    end
end
