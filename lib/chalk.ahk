class Chalker {
    ; TODO: Background colors

    static _colorCodes := { black: "[30m", red: "[31m", green: "[32m", yellow: "[33m", blue: "[34m", magenta: "[35m", cyan: "[36m", white: "[37m" }

    static _bgColorCodes := { bgBlack: "[40m", bgRed: "[41m", bgGreen: "[42m", bgYellow: "[43m", bgBlue: "[44m", bgMagenta: "[45m", bgCyan: "[46m", bgWhite: "[47m" }

    static _modifierCodes := { bold: "[1m", dim: "[2m", italic: "[3m", underline: "[4m", overline: "[53m", inverse: "[7m", hidden: "[8m", strikethrough: "[9m" }

    static _reset := "[0m"

    _colorState := ""
    _bgColorState := ""
    _modifierState := { bold: false, dim: false, italic: false, underline: false, overline: false, inverse: false, hidden: false, strikethrough: false }

    __Get(propName) {
        for k, v in Chalker._colorCodes {
            if (k == propName) {
                this._colorState := propName
                return this
            }
        }

        for k, v in Chalker._bgColorCodes {
            if (k == propName) {
                this._bgColorState := propName
                return this
            }
        }

        for k, v in Chalker._modifierCodes {
            if (k == propName) {
                this._modifierState[propName] := true
                return this
            }
        }

        throw "Unknown property: " . propName
    }

    __Call(methodName, str) {
        isColor := false
        for k, v in Chalker._colorCodes {
            if (k == methodName) {
                this._colorState := methodName
                isColor := true
                break
            }
        }

        isBgColor := false
        for k, v in Chalker._bgColorCodes {
            if (k == methodName) {
                this._bgColorState := methodName
                isBgColor := true
                break
            }
        }

        isModifier := false
        if (!isColor && !isBgColor) {
            for k, v in Chalker._modifierCodes {
                if (k == methodName) {
                    this._modifierState[methodName] := true
                    isModifier := true
                    break
                }
            }
        }
        
        if (!isColor && !isBgColor && !isModifier) {
            throw "Unknown method: " . methodName
        }

        ; Combine all specified colors and modifiers into a single prefix
        prefix := ""
        if (this._colorState != "") {
            prefix .= Chalker._colorCodes[this._colorState]
        }
        if (this._bgColorState != "") {
            prefix .= Chalker._bgColorCodes[this._bgColorState]
        }
        for k, v in this._modifierState {
            if (v == true) {
                prefix .= Chalker._modifierCodes[k]
            }
        }

        ; Reset state
        this._colorState := ""
        this._bgColorState := ""
        for k, v in this._modifierState {
            this._modifierState[k] := false
        }

        ; Return the final string
        return prefix str Chalker._reset
    }
}