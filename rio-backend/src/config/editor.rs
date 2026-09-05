// RIO-CONFIG-UI-001: a finite editor inventory, not a second configuration schema.
use super::{window::WindowBlur, Config};
use serde::Serialize;

#[derive(Serialize)]
struct Field {
    path: &'static str,
    kind: &'static str,
    description: &'static str,
    #[serde(skip_serializing_if = "Option::is_none")]
    default: Option<toml::Value>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    choices: Vec<toml::Value>,
}

#[derive(Serialize)]
struct Inventory {
    version: u8,
    fields: Vec<Field>,
}

/// Validate native TOML without loading assets or opening a window, then describe
/// the global settings supported by the editor. Platform overrides still win.
pub fn describe(raw: &str) -> Result<String, Box<dyn std::error::Error>> {
    let _: Config = toml::from_str(raw)?;
    let defaults = toml::Value::try_from(Config::default())?;
    let mut fields = Vec::new();
    for (path, kind, description) in [
        ("window.blur", "choice", "Background blur where supported by the compositor. Glass styles require macOS 26; elsewhere they fall back to system blur. Platform window overrides take precedence."),
        ("window.opacity", "number", "Background opacity, from transparent (0) to opaque (1). Platform window overrides take precedence."),
        ("fonts.family", "string", "Global font family override. Unset uses the individual regular, bold and italic font faces."),
        ("fonts.size", "number", "Font size in points."),
        ("line-height", "number", "Line height multiplier."),
        ("effects.trail-cursor", "boolean", "Animate a trail when the terminal cursor moves."),
        ("bell.audio", "boolean", "Play the system bell. Linux/BSD requires a build with the audio feature."),
        ("confirm-before-quit", "boolean", "Ask for confirmation before quitting Rio."),
    ] {
        let default = path.split('.').try_fold(&defaults, |value, key| value.get(key)).cloned();
        let choices = if path == "window.blur" {
            [WindowBlur::Off, WindowBlur::System, WindowBlur::MacosGlassRegular, WindowBlur::MacosGlassClear]
                .into_iter().map(toml::Value::try_from).collect::<Result<_, _>>()?
        } else {
            Vec::new()
        };
        fields.push(Field { path, kind, description, default, choices });
    }
    Ok(toml::to_string(&Inventory { version: 1, fields })?)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn config_editor_uses_native_defaults_and_validation() {
        let inventory: toml::Value = toml::from_str(&describe("").unwrap()).unwrap();
        assert_eq!(inventory["version"].as_integer(), Some(1));
        let blur = inventory["fields"]
            .as_array()
            .unwrap()
            .iter()
            .find(|field| field["path"].as_str() == Some("window.blur"))
            .unwrap();
        assert_eq!(blur["default"].as_bool(), Some(false));
        for value in blur["choices"].as_array().unwrap() {
            describe(&format!("[window]\nblur = {value}\n")).unwrap();
        }
        describe("theme = 'not-installed'\n[fonts]\nsize = 18.0\n").unwrap();
        assert!(describe("[window]\nblur = 'invalid'\n").is_err());
        assert!(describe("[fonts]\nsize = 'large'\n").is_err());
    }
}
