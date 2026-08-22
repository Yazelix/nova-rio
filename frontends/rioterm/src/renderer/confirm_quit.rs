// Copyright (c) 2023-present, Raphael Amorim.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

use rio_backend::sugarloaf::text::DrawOpts;
use rio_backend::sugarloaf::Sugarloaf;

const HEADING: &str = "want to quit?";
const CONFIRM: &str = "yes (y)";
const DISMISS: &str = "no (n)";

#[derive(Default)]
pub struct ConfirmQuit {
    active: bool,
}

impl ConfirmQuit {
    #[inline]
    pub fn is_active(&self) -> bool {
        self.active
    }

    #[inline]
    pub fn set_active(&mut self, active: bool) {
        self.active = active;
    }

    /// `dimensions` is `(window_width, window_height, scale_factor)`,
    /// matching the other overlays' `render` signature.
    pub fn render(&self, sugarloaf: &mut Sugarloaf, dimensions: (f32, f32, f32)) {
        if !self.active {
            return;
        }

        let (width, height, scale) = dimensions;
        let win_w = width / scale;
        let win_h = height / scale;

        let suffix = format!("  {}  /  {}", CONFIRM, DISMISS);
        let heading_opts = DrawOpts {
            font_size: 13.0,
            color: [255, 255, 255, 255],
            ..DrawOpts::default()
        };
        let gray_opts = DrawOpts {
            color: [166, 166, 166, 255],
            ..heading_opts
        };
        let text_w = {
            let ui = sugarloaf.text_mut();
            ui.measure(HEADING, &heading_opts) + ui.measure(&suffix, &gray_opts)
        };
        let padding_x = 18.0;
        let padding_y = 6.0;
        let text_h = 16.0;
        let box_w = text_w + padding_x * 2.0;
        let box_h = text_h + padding_y * 2.0;
        let box_x = (win_w - box_w) / 2.0;
        let box_y = (win_h - box_h) / 2.0;

        sugarloaf.rounded_rect(
            None,
            box_x - 1.0,
            box_y - 1.0,
            box_w + 2.0,
            box_h + 2.0,
            [1.0, 0.29, 0.01, 1.0],
            0.0,
            7.0,
            20,
        );
        sugarloaf.rounded_rect(
            None,
            box_x,
            box_y,
            box_w,
            box_h,
            [0.055, 0.06, 0.07, 1.0],
            0.0,
            6.0,
            21,
        );

        let text_x = box_x + padding_x;
        let text_y = box_y + padding_y;

        let ui = sugarloaf.text_mut();
        let heading_w = ui.draw(text_x, text_y, HEADING, &heading_opts);
        ui.draw(text_x + heading_w, text_y, &suffix, &gray_opts);
    }
}
