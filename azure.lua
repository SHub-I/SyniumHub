return {
    WindowColor = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 24, 10)),
        ColorSequenceKeypoint.new(0.9999, Color3.fromRGB(46, 34, 14)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 42, 18)),
    }),

    ShadowColor = Color3.fromRGB(18, 12, 6),

    ElementStroke = Color3.fromRGB(90, 70, 30),
    ElementGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(48, 36, 16)),
        ColorSequenceKeypoint.new(0.9999, Color3.fromRGB(54, 40, 18)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 40, 18)),
    }),
    ElementStrokeGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 90, 40)),
        ColorSequenceKeypoint.new(0.9999, Color3.fromRGB(140, 110, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 90, 40)),
    }),
    ElementStrokeHover = Color3.fromRGB(160, 120, 60),

    TabBackground = ColorSequence.new(
        Color3.fromRGB(70, 52, 22),
        Color3.fromRGB(46, 34, 14)
    ),
    TabStroke = ColorSequence.new(
        Color3.fromRGB(160, 120, 60),
        Color3.fromRGB(70, 52, 22)
    ),

    SliderBackground = Color3.fromRGB(60, 45, 20),
    SliderBackgroundHover = Color3.fromRGB(80, 60, 28),
    SliderProgress = ColorSequence.new(
        Color3.fromRGB(255, 80, 60),
        Color3.fromRGB(200, 40, 30)
    ),

    AccentColor = Color3.fromRGB(255, 70, 50),
    AccentStroke = Color3.fromRGB(255, 120, 90),

    ToggleKnobOff = Color3.fromRGB(240, 220, 180),

    StatBackground = Color3.fromRGB(40, 30, 14),

    DropdownHighlight = Color3.fromRGB(255, 70, 50),

    NeutralButton = Color3.fromRGB(60, 45, 20),
    NeutralButtonHover = Color3.fromRGB(80, 60, 28),
    NeutralButtonStroke = Color3.fromRGB(160, 120, 60),
}
