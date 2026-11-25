# 81 mockup Sweet Rope

Viewport 1080 × 2340. Dựng tĩnh bằng Pillow, có nhãn MOCKUP. JPEG Sort Streak dùng để đối chiếu trạng thái. Một số thành phần (logo, cúp/rank, animation) dùng art minh họa của bản demo, đánh dấu theo nguồn trong bảng lớp.

Bản FullRun dựng lại 81 ảnh bằng lớp hiển thị và chữ đã ghi trong hai CSV bố cục. Bản dựng dùng nền Orchard mới, ghép ba đoạn Godot ở các dây màu, và đặt ô Order trống theo đúng hình chậu. Chữ Orchard có thẻ nền riêng. Hai CSV giữ tọa độ và đường dẫn của bản dựng cơ sở để đối chiếu. Giữ chữ Sweet Rope tạm cho logo trong các hình xem trước.

Đọc `reference_coverage.csv` để so từng ảnh nguồn. `sprite_layers.csv` trỏ tới asset trong handoff hoặc `review_sprites/`; các lớp review hỗ trợ duyệt mockup và chưa thuộc manifest production. `dynamic_text.csv` dùng để đối chiếu thứ tự lớp.

| Mockup | Trạng thái ảnh tham chiếu | JPEG tham chiếu |
|---|---|---|
| [logo_oakever](01_logo/logo_oakever.png) | Logo hãng | `01_Logo/logo_oakever.jpg` |
| [splash_loading](01_logo/splash_loading.png) | Splash / tải game | `01_Logo/splash_loading.jpg` |
| [home_bonus_level](02_home/home_bonus_level.png) | Home, nút Bonus Level | `02_Home/home_bonus_level.jpg` |
| [home_scene1](02_home/home_scene1.png) | Home, Scene 1 đang ghép | `02_Home/home_scene1.jpg` |
| [home_scene2](02_home/home_scene2.png) | Home, nền scene mới | `02_Home/home_scene2.jpg` |
| [home_scene_complete](02_home/home_scene_complete.png) | Home, scene ghép đủ 25/25 | `02_Home/home_scene_complete.jpg` |
| [home_super_hard](02_home/home_super_hard.png) | Home, nút Super Hard | `02_Home/home_super_hard.jpg` |
| [gameplay_last_step](03_gameplay/gameplay_last_step.png) | Còn một nước là thắng | `03_Gameplay/gameplay_last_step.jpg` |
| [gameplay_level12_locked](03_gameplay/gameplay_level12_locked.png) | Level 12, locked rope | `03_Gameplay/gameplay_level12_locked.jpg` |
| [gameplay_level15_hard](03_gameplay/gameplay_level15_hard.png) | Level 15, Hard | `03_Gameplay/gameplay_level15_hard.jpg` |
| [gameplay_level1_start](03_gameplay/gameplay_level1_start.png) | Level 1 | `03_Gameplay/gameplay_level1_start.jpg` |
| [gameplay_level3_start](03_gameplay/gameplay_level3_start.png) | Level 3 | `03_Gameplay/gameplay_level3_start.jpg` |
| [gameplay_level40_hard](03_gameplay/gameplay_level40_hard.png) | Level 40, Hard | `03_Gameplay/gameplay_level40_hard.jpg` |
| [gameplay_level7_hidden](03_gameplay/gameplay_level7_hidden.png) | Level 7, hidden | `03_Gameplay/gameplay_level7_hidden.jpg` |
| [gameplay_sunlight_ice_1](03_gameplay/gameplay_sunlight_ice_1.png) | Sunlight + băng, level mẫu 1 | `03_Gameplay/gameplay_sunlight_ice_1.jpg` |
| [gameplay_sunlight_ice_2](03_gameplay/gameplay_sunlight_ice_2.png) | Sunlight + băng, level mẫu 2 | `03_Gameplay/gameplay_sunlight_ice_2.jpg` |
| [gameplay_sunlight_ice_3](03_gameplay/gameplay_sunlight_ice_3.png) | Sunlight + băng, level mẫu 3 | `03_Gameplay/gameplay_sunlight_ice_3.jpg` |
| [gameplay_super_hard](03_gameplay/gameplay_super_hard.png) | Super Hard | `03_Gameplay/gameplay_super_hard.jpg` |
| [gameplay_test_8_columns](03_gameplay/gameplay_test_8_columns.png) | Bàn test 8 rope | `03_Gameplay/gameplay_test_8_columns.jpg` |
| [gameplay_test_challenge](03_gameplay/gameplay_test_challenge.png) | Bàn test Challenge | `03_Gameplay/gameplay_test_challenge.jpg` |
| [gameplay_test_golden_pig](03_gameplay/gameplay_test_golden_pig.png) | Bàn test Golden Pig | `03_Gameplay/gameplay_test_golden_pig.jpg` |
| [gameplay_test_long_rope](03_gameplay/gameplay_test_long_rope.png) | Bàn test rope dài | `03_Gameplay/gameplay_test_long_rope.jpg` |
| [helper_extra_rope](03_gameplay/helper_extra_rope.png) | Helper Extra Rope | `03_Gameplay/helper_extra_rope.jpg` |
| [helper_fill_container_after](03_gameplay/helper_fill_container_after.png) | Fill Container xong | `03_Gameplay/helper_fill_container_after.jpg` |
| [helper_fill_container_motion](03_gameplay/helper_fill_container_motion.png) | Fill Container đang chạy | `03_Gameplay/helper_fill_container_motion.jpg` |
| [helper_hint](03_gameplay/helper_hint.png) | Helper Hint | `03_Gameplay/helper_hint.jpg` |
| [dead_no_moves_1](04_popup/dead_no_moves_1.png) | Hết nước đi | `04_Popup/dead_no_moves_1.jpg` |
| [dead_no_moves_2](04_popup/dead_no_moves_2.png) | Hết nước đi | `04_Popup/dead_no_moves_2.jpg` |
| [dialog_avatar_select](04_popup/dialog_avatar_select.png) | Profile / chọn avatar | `04_Popup/dialog_avatar_select.jpg` |
| [dialog_confirm](04_popup/dialog_confirm.png) | Xác nhận thoát level | `04_Popup/dialog_confirm.jpg` |
| [dialog_privacy](04_popup/dialog_privacy.png) | Privacy | `04_Popup/dialog_privacy.jpg` |
| [dialog_rank_change](04_popup/dialog_rank_change.png) | Kết thúc season | `04_Popup/dialog_rank_change.jpg` |
| [dialog_rank_introduction](04_popup/dialog_rank_introduction.png) | Giới thiệu Rank | `04_Popup/dialog_rank_introduction.jpg` |
| [dialog_rank_new_season](04_popup/dialog_rank_new_season.png) | Season mới | `04_Popup/dialog_rank_new_season.jpg` |
| [dialog_rank_season_win](04_popup/dialog_rank_season_win.png) | Thắng season | `04_Popup/dialog_rank_season_win.jpg` |
| [dialog_reset_confirm](04_popup/dialog_reset_confirm.png) | Xác nhận Reset | `04_Popup/dialog_reset_confirm.jpg` |
| [dialog_setting](04_popup/dialog_setting.png) | Settings | `04_Popup/dialog_setting.jpg` |
| [dialog_special_challenge_reward](04_popup/dialog_special_challenge_reward.png) | Thưởng Special Challenge | `04_Popup/dialog_special_challenge_reward.jpg` |
| [dialog_timed_endless_reward](04_popup/dialog_timed_endless_reward.png) | Thưởng Endless | `04_Popup/dialog_timed_endless_reward.jpg` |
| [finish_result](04_popup/finish_result.png) | Kết quả thắng | `04_Popup/finish_result.jpg` |
| [finish_result_fantastic](04_popup/finish_result_fantastic.png) | Kết quả thắng, lời khen khác | `04_Popup/finish_result_fantastic.jpg` |
| [helper_unlock_hint](04_popup/helper_unlock_hint.png) | Mở khóa helper hint | `04_Popup/helper_unlock_hint.jpg` |
| [helper_unlock_rope](04_popup/helper_unlock_rope.png) | Mở khóa helper rope | `04_Popup/helper_unlock_rope.jpg` |
| [helper_unlock_undo](04_popup/helper_unlock_undo.png) | Mở khóa helper undo | `04_Popup/helper_unlock_undo.jpg` |
| [rank_finish_climb](04_popup/rank_finish_climb.png) | Rank cuối ván, tăng hạng | `04_Popup/rank_finish_climb.jpg` |
| [rank_finish_continue](04_popup/rank_finish_continue.png) | Rank cuối ván, nút Continue | `04_Popup/rank_finish_continue.jpg` |
| [rank_finish_enter](04_popup/rank_finish_enter.png) | Rank cuối ván, đang vào | `04_Popup/rank_finish_enter.jpg` |
| [streak_12](04_popup/streak_12.png) | Popup Streak 12 | `04_Popup/streak_12.jpg` |
| [streak_3](04_popup/streak_3.png) | Popup Streak 3 | `04_Popup/streak_3.jpg` |
| [streak_7](04_popup/streak_7.png) | Popup Streak 7 | `04_Popup/streak_7.jpg` |
| [win_motion_01](04_popup/win_motion_01.png) | Thắng: xu bay | `04_Popup/win_motion_01.jpg` |
| [win_motion_02](04_popup/win_motion_02.png) | Thắng: vật phẩm rank bay | `04_Popup/win_motion_02.jpg` |
| [banner_bonus_1](05_banner/banner_bonus_1.png) | Banner Bonus Level, khung 1 | `05_Banner/banner_bonus_1.jpg` |
| [banner_bonus_2](05_banner/banner_bonus_2.png) | Banner Bonus Level, khung 2 | `05_Banner/banner_bonus_2.jpg` |
| [banner_challenge_1](05_banner/banner_challenge_1.png) | Banner Challenge, khung 1 | `05_Banner/banner_challenge_1.jpg` |
| [banner_challenge_2](05_banner/banner_challenge_2.png) | Banner Challenge, khung 2 | `05_Banner/banner_challenge_2.jpg` |
| [banner_combo_fullscreen_fx_1](05_banner/banner_combo_fullscreen_fx_1.png) | Combo toàn màn, khung 1 | `05_Banner/banner_combo_fullscreen_fx_1.jpg` |
| [banner_combo_fullscreen_fx_2](05_banner/banner_combo_fullscreen_fx_2.png) | Combo toàn màn, khung 2 | `05_Banner/banner_combo_fullscreen_fx_2.jpg` |
| [banner_combo_preview_1](05_banner/banner_combo_preview_1.png) | Chữ Combo, khung 1 | `05_Banner/banner_combo_preview_1.jpg` |
| [banner_combo_preview_2](05_banner/banner_combo_preview_2.png) | Chữ Combo, khung 2 | `05_Banner/banner_combo_preview_2.jpg` |
| [banner_good_luck_1](05_banner/banner_good_luck_1.png) | Chữ Good Luck, khung 1 | `05_Banner/banner_good_luck_1.jpg` |
| [banner_good_luck_2](05_banner/banner_good_luck_2.png) | Chữ Good Luck, khung 2 | `05_Banner/banner_good_luck_2.jpg` |
| [banner_hard_1](05_banner/banner_hard_1.png) | Banner Hard, khung 1 | `05_Banner/banner_hard_1.jpg` |
| [banner_hard_2](05_banner/banner_hard_2.png) | Banner Hard, khung 2 | `05_Banner/banner_hard_2.jpg` |
| [banner_smart_move_1](05_banner/banner_smart_move_1.png) | Chữ Smart Move, khung 1 | `05_Banner/banner_smart_move_1.jpg` |
| [banner_smart_move_2](05_banner/banner_smart_move_2.png) | Chữ Smart Move, khung 2 | `05_Banner/banner_smart_move_2.jpg` |
| [banner_streak_1](05_banner/banner_streak_1.png) | Banner Streak, khung 1 | `05_Banner/banner_streak_1.jpg` |
| [banner_streak_2](05_banner/banner_streak_2.png) | Banner Streak, khung 2 | `05_Banner/banner_streak_2.jpg` |
| [banner_streak_trophy_1](05_banner/banner_streak_trophy_1.png) | Cúp Streak đang vào, khung 1 | `05_Banner/banner_streak_trophy_1.jpg` |
| [banner_streak_trophy_2](05_banner/banner_streak_trophy_2.png) | Cúp Streak đang vào, khung 2 | `05_Banner/banner_streak_trophy_2.jpg` |
| [banner_super_hard_1](05_banner/banner_super_hard_1.png) | Banner Super Hard, khung 1 | `05_Banner/banner_super_hard_1.jpg` |
| [banner_super_hard_2](05_banner/banner_super_hard_2.png) | Banner Super Hard, khung 2 | `05_Banner/banner_super_hard_2.jpg` |
| [guide_hidden](05_banner/guide_hidden.png) | Hướng dẫn hidden | `05_Banner/guide_hidden.jpg` |
| [guide_locked_rope](05_banner/guide_locked_rope.png) | Hướng dẫn locked rope | `05_Banner/guide_locked_rope.jpg` |
| [guide_sunlight_ice](05_banner/guide_sunlight_ice.png) | Hướng dẫn Sunlight / băng | `05_Banner/guide_sunlight_ice.jpg` |
| [daily_checkin_1](06_meta/daily_checkin_1.png) | Daily Check-in, vào màn | `06_Meta/daily_checkin_1.jpg` |
| [daily_checkin_2](06_meta/daily_checkin_2.png) | Daily Check-in, đang mở quà | `06_Meta/daily_checkin_2.jpg` |
| [daily_checkin_3](06_meta/daily_checkin_3.png) | Daily Check-in, nhận xu | `06_Meta/daily_checkin_3.jpg` |
| [daily_checkin_4](06_meta/daily_checkin_4.png) | Daily Check-in, hoàn tất | `06_Meta/daily_checkin_4.jpg` |
| [new_scene_unlock](06_meta/new_scene_unlock.png) | Mở scene mới | `06_Meta/new_scene_unlock.jpg` |
| [rank_page](06_meta/rank_page.png) | Trang Rank | `06_Meta/rank_page.jpg` |
