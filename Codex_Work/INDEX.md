# Sort Streak: Full Scenes (art tham khảo cho Sweet Rope)

Chỉ dùng để tham khảo. Không đưa asset của Sort Streak vào sản phẩm Sweet Rope.

Ảnh chụp từ game đang chạy trên PC (Sort Streak 1.0.10 bản giải nén, Godot 4.6.1 + Spine), 1080×2340, safe area đặt bằng 0, không có banner quảng cáo. Tên người chơi và bảng xếp hạng là dữ liệu của bản chạy thử.

- **Luồng thật**: thao tác như người chơi.
- **Lệnh debug**: tạo trạng thái bằng lệnh debug có sẵn của game, sau đó game tự vẽ. Bàn "test" không phải level thật.
- **Mở trực tiếp**: mở màn không kèm dữ liệu. Số và chữ có thể là giá trị giữ chỗ (ví dụ hạng `#-1`, thưởng `x0`), chưa xác thực.

| File | Màn / trạng thái | Cách mở | Loại | Scene |
|---|---|---|---|---|
| `01_Logo/logo_oakever.jpg` | Logo hãng | page-show logo | Mở trực tiếp | `scripts/main/pages/logo/logo_page.tscn` |
| `01_Logo/splash_loading.jpg` | Splash / tải game | page-show splash | Mở trực tiếp | `scripts/main/pages/splash/splash_page.tscn` |
| `02_Home/home_bonus_level.jpg` | Home, nút Bonus Level | bonus_level | Lệnh debug | `scripts/main/pages/home/home_page.tscn` |
| `02_Home/home_scene1.jpg` | Home, Scene 1 đang ghép | page-show home | Luồng thật | `scripts/main/pages/home/home_page.tscn` |
| `02_Home/home_scene2.jpg` | Home, nền scene mới | page-show home | Luồng thật | `scripts/main/pages/home/home_page.tscn` |
| `02_Home/home_scene_complete.jpg` | Home, scene ghép đủ 25/25 | thắng level 25 | Lệnh debug | `scripts/main/pages/home/home_page.tscn` |
| `02_Home/home_super_hard.jpg` | Home, nút Super Hard | sau khi thắng, next_super_hard | Lệnh debug | `scripts/main/pages/home/home_page.tscn` |
| `03_Gameplay/gameplay_last_step.jpg` | Còn một nước là thắng | last_cup | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level12_locked.jpg` | Level 12, locked rope | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level15_hard.jpg` | Level 15, Hard | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level1_start.jpg` | Level 1 | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level3_start.jpg` | Level 3 | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level40_hard.jpg` | Level 40, Hard | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level7_hidden.jpg` | Level 7, hidden | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_sunlight_ice_1.jpg` | Sunlight + băng, level mẫu 1 | API juice-level, juice_sunlight_levels.json | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_sunlight_ice_2.jpg` | Sunlight + băng, level mẫu 2 | API juice-level, juice_sunlight_levels.json | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_sunlight_ice_3.jpg` | Sunlight + băng, level mẫu 3 | API juice-level, juice_sunlight_levels.json | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_super_hard.jpg` | Super Hard | next_super_hard + level 16 | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_test_8_columns.jpg` | Bàn test 8 rope | eight_columns | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_test_challenge.jpg` | Bàn test Challenge | challenge_time | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_test_golden_pig.jpg` | Bàn test Golden Pig | bonus_start_test | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_test_long_rope.jpg` | Bàn test rope dài | long_rope | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/helper_extra_rope.jpg` | Helper Extra Rope | bấm nút Rope | Luồng thật | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/helper_fill_container_after.jpg` | Fill Container xong | complete_column | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/helper_fill_container_motion.jpg` | Fill Container đang chạy | complete_column | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/helper_hint.jpg` | Helper Hint | bấm nút Hint | Luồng thật | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/dead_no_moves_1.jpg` | Hết nước đi | sort_die | Lệnh debug | `scripts/main/dialogs/game_dead_toast/game_dead_toast.tscn` |
| `04_Popup/dead_no_moves_2.jpg` | Hết nước đi | sort_die | Lệnh debug | `scripts/main/dialogs/game_dead_toast/game_dead_toast.tscn` |
| `04_Popup/dialog_avatar_select.jpg` | Profile / chọn avatar | page-show avatar_select | Mở trực tiếp | `scripts/main/dialogs/avatar_select/avatar_select_dialog.tscn` |
| `04_Popup/dialog_confirm.jpg` | Xác nhận thoát level | page-show confirm | Mở trực tiếp | `scripts/main/dialogs/confirm/confirm_dialog.tscn` |
| `04_Popup/dialog_privacy.jpg` | Privacy | page-show privacy | Mở trực tiếp | `scripts/main/dialogs/privacy/privacy_dialog.tscn` |
| `04_Popup/dialog_rank_change.jpg` | Kết thúc season | page-show rank_change | Mở trực tiếp | `scripts/main/dialogs/rank_change/rank_change_dialog.tscn` |
| `04_Popup/dialog_rank_introduction.jpg` | Giới thiệu Rank | page-show rank_introduction | Mở trực tiếp | `scripts/main/dialogs/rank_introduction/rank_introduction_dialog.tscn` |
| `04_Popup/dialog_rank_new_season.jpg` | Season mới | page-show rank_new_season | Mở trực tiếp | `scripts/main/dialogs/rank_new_season/rank_new_season_dialog.tscn` |
| `04_Popup/dialog_rank_season_win.jpg` | Thắng season | page-show rank_season_win | Mở trực tiếp | `scripts/main/dialogs/rank_season_win/rank_season_win_page.tscn` |
| `04_Popup/dialog_reset_confirm.jpg` | Xác nhận Reset | page-show reset_confirm | Mở trực tiếp | `scripts/main/dialogs/reset_confirm/reset_confirm_dialog.tscn` |
| `04_Popup/dialog_setting.jpg` | Settings | page-show setting | Mở trực tiếp | `scripts/main/dialogs/settings/settings_dialog.tscn` |
| `04_Popup/dialog_special_challenge_reward.jpg` | Thưởng Special Challenge | page-show special_challenge_reward | Mở trực tiếp | `scripts/main/dialogs/special_challenge_reward/special_challenge_reward_dialog.tscn` |
| `04_Popup/dialog_timed_endless_reward.jpg` | Thưởng Endless | page-show timed_endless_reward | Mở trực tiếp | `scripts/main/dialogs/timed_endless_reward/timed_endless_reward_dialog.tscn` |
| `04_Popup/finish_result.jpg` | Kết quả thắng | win_round | Lệnh debug | `scripts/main/dialogs/finish/finish_dialog.tscn` |
| `04_Popup/finish_result_fantastic.jpg` | Kết quả thắng, lời khen khác | thắng level 25 | Lệnh debug | `scripts/main/dialogs/finish/finish_dialog.tscn` |
| `04_Popup/helper_unlock_hint.jpg` | Mở khóa helper hint | prop_unlock_preview hint | Lệnh debug | `scripts/main/dialogs/prop_unlock/prop_unlock_dialog.tscn` |
| `04_Popup/helper_unlock_rope.jpg` | Mở khóa helper rope | prop_unlock_preview rope | Lệnh debug | `scripts/main/dialogs/prop_unlock/prop_unlock_dialog.tscn` |
| `04_Popup/helper_unlock_undo.jpg` | Mở khóa helper undo | prop_unlock_preview undo | Lệnh debug | `scripts/main/dialogs/prop_unlock/prop_unlock_dialog.tscn` |
| `04_Popup/rank_finish_climb.jpg` | Rank cuối ván, tăng hạng | thắng level 25 | Lệnh debug | `scripts/main/pages/rank_game_finish/rank_game_finish_page.tscn` |
| `04_Popup/rank_finish_continue.jpg` | Rank cuối ván, nút Continue | win_round | Lệnh debug | `scripts/main/pages/rank_game_finish/rank_game_finish_page.tscn` |
| `04_Popup/rank_finish_enter.jpg` | Rank cuối ván, đang vào | win_round | Lệnh debug | `scripts/main/pages/rank_game_finish/rank_game_finish_page.tscn` |
| `04_Popup/streak_12.jpg` | Popup Streak 12 | streak_popup_1 12 | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/streak_3.jpg` | Popup Streak 3 | streak_popup_1 3 | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/streak_7.jpg` | Popup Streak 7 | streak_popup_1 7 | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/win_motion_01.jpg` | Thắng: xu bay | win_round | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/win_motion_02.jpg` | Thắng: vật phẩm rank bay | win_round | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_bonus_1.jpg` | Banner Bonus Level, khung 1 | bonus_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_bonus_2.jpg` | Banner Bonus Level, khung 2 | bonus_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_challenge_1.jpg` | Banner Challenge, khung 1 | challenge_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_challenge_2.jpg` | Banner Challenge, khung 2 | challenge_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_combo_fullscreen_fx_1.jpg` | Combo toàn màn, khung 1 | combo_fullscreen_fx | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_combo_fullscreen_fx_2.jpg` | Combo toàn màn, khung 2 | combo_fullscreen_fx | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_combo_preview_1.jpg` | Chữ Combo, khung 1 | combo_preview | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_combo_preview_2.jpg` | Chữ Combo, khung 2 | combo_preview | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_good_luck_1.jpg` | Chữ Good Luck, khung 1 | good_luck | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_good_luck_2.jpg` | Chữ Good Luck, khung 2 | good_luck | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_hard_1.jpg` | Banner Hard, khung 1 | hard_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_hard_2.jpg` | Banner Hard, khung 2 | hard_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_smart_move_1.jpg` | Chữ Smart Move, khung 1 | smart_move | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_smart_move_2.jpg` | Chữ Smart Move, khung 2 | smart_move | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_streak_1.jpg` | Banner Streak, khung 1 | streak_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_streak_2.jpg` | Banner Streak, khung 2 | streak_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_streak_trophy_1.jpg` | Cúp Streak đang vào, khung 1 | vào level khi đang có streak | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_streak_trophy_2.jpg` | Cúp Streak đang vào, khung 2 | vào level khi đang có streak | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_super_hard_1.jpg` | Banner Super Hard, khung 1 | super_hard_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_super_hard_2.jpg` | Banner Super Hard, khung 2 | super_hard_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/guide_hidden.jpg` | Hướng dẫn hidden | mở game với save đang ở level 7 | Luồng thật | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/guide_locked_rope.jpg` | Hướng dẫn locked rope | vào level sau bonus_level | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/guide_sunlight_ice.jpg` | Hướng dẫn Sunlight / băng | sunlight_pot_level | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `06_Meta/daily_checkin_1.jpg` | Daily Check-in, vào màn | daily_checkin_preview | Lệnh debug | `scripts/main/dialogs/daily_first_win_checkin/daily_first_win_checkin_dialog.tscn` |
| `06_Meta/daily_checkin_2.jpg` | Daily Check-in, đang mở quà | daily_checkin_preview | Lệnh debug | `scripts/main/dialogs/daily_first_win_checkin/daily_first_win_checkin_dialog.tscn` |
| `06_Meta/daily_checkin_3.jpg` | Daily Check-in, nhận xu | daily_checkin_preview | Lệnh debug | `scripts/main/dialogs/daily_first_win_checkin/daily_first_win_checkin_dialog.tscn` |
| `06_Meta/daily_checkin_4.jpg` | Daily Check-in, hoàn tất | daily_checkin_preview | Lệnh debug | `scripts/main/dialogs/daily_first_win_checkin/daily_first_win_checkin_dialog.tscn` |
| `06_Meta/new_scene_unlock.jpg` | Mở scene mới | thắng level 25 | Lệnh debug | `scripts/gameplay/outer_loop/view/new_scene_page.tscn` |
| `06_Meta/rank_page.jpg` | Trang Rank | page-show rank | Mở trực tiếp | `scripts/main/pages/rank/rank_page.tscn` |

## Chưa lấy được

- Màn chơi Endless: game ngừng phản hồi khi mở bằng `juice_endless` (thử 2 lần). Chỉ có popup thưởng Endless.
- Popup Finish Ad Reward và lớp Loading: mở trực tiếp chỉ ra màn trống.
- Hướng dẫn bàn tay ở level 1.
- Băng kiểu chặn ghép (blockConnection) và Container đóng băng.
- Thua do hết giờ, shop, banner quảng cáo.
- Animation: chỉ có vài khung tĩnh, không có video.
