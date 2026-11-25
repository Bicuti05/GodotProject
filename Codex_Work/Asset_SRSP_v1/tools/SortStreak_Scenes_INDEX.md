# Sort Streak: Full Scenes (art tham khảo cho Sweet Rope)

Chỉ dùng để tham khảo. Không đưa asset của Sort Streak vào sản phẩm Sweet Rope.

Ảnh chụp từ game đang chạy trên PC (Sort Streak 1.0.10 bản giải nén, Godot 4.6.1 + Spine), 1080×2340, safe area đặt bằng 0, không có banner quảng cáo. Tên người chơi và bảng xếp hạng là dữ liệu của bản chạy thử.

- **Luồng thật**: thao tác như người chơi.
- **Lệnh debug**: tạo trạng thái bằng lệnh debug có sẵn của game, sau đó game tự vẽ. Bàn "test" không phải level thật.
- **Mở trực tiếp**: mở màn không kèm dữ liệu. Số và chữ có thể là giá trị giữ chỗ (ví dụ hạng `#-1`, thưởng `x0`), chưa xác thực.

| File | Màn / trạng thái | Cách mở | Loại | Scene |
|---|---|---|---|---|
| `01_Logo/logo_oakever.png` | Logo hãng | page-show logo | Mở trực tiếp | `scripts/main/pages/logo/logo_page.tscn` |
| `01_Logo/splash_loading.png` | Splash / tải game | page-show splash | Mở trực tiếp | `scripts/main/pages/splash/splash_page.tscn` |
| `02_Home/home_bonus_level.png` | Home, nút Bonus Level | bonus_level | Lệnh debug | `scripts/main/pages/home/home_page.tscn` |
| `02_Home/home_scene1.png` | Home, Scene 1 đang ghép | page-show home | Luồng thật | `scripts/main/pages/home/home_page.tscn` |
| `02_Home/home_scene2.png` | Home, nền scene mới | page-show home | Luồng thật | `scripts/main/pages/home/home_page.tscn` |
| `02_Home/home_scene_complete.png` | Home, scene ghép đủ 25/25 | thắng level 25 | Lệnh debug | `scripts/main/pages/home/home_page.tscn` |
| `02_Home/home_super_hard.png` | Home, nút Super Hard | sau khi thắng, next_super_hard | Lệnh debug | `scripts/main/pages/home/home_page.tscn` |
| `03_Gameplay/gameplay_last_step.png` | Còn một nước là thắng | last_cup | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level12_locked.png` | Level 12, locked rope | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level15_hard.png` | Level 15, Hard | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level1_start.png` | Level 1 | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level3_start.png` | Level 3 | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level40_hard.png` | Level 40, Hard | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_level7_hidden.png` | Level 7, hidden | level n | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_sunlight_ice_1.png` | Sunlight + băng, level mẫu 1 | API juice-level, juice_sunlight_levels.json | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_sunlight_ice_2.png` | Sunlight + băng, level mẫu 2 | API juice-level, juice_sunlight_levels.json | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_sunlight_ice_3.png` | Sunlight + băng, level mẫu 3 | API juice-level, juice_sunlight_levels.json | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_super_hard.png` | Super Hard | next_super_hard + level 16 | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_test_8_columns.png` | Bàn test 8 rope | eight_columns | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_test_challenge.png` | Bàn test Challenge | challenge_time | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_test_golden_pig.png` | Bàn test Golden Pig | bonus_start_test | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/gameplay_test_long_rope.png` | Bàn test rope dài | long_rope | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/helper_extra_rope.png` | Helper Extra Rope | bấm nút Rope | Luồng thật | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/helper_fill_container_after.png` | Fill Container xong | complete_column | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/helper_fill_container_motion.png` | Fill Container đang chạy | complete_column | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `03_Gameplay/helper_hint.png` | Helper Hint | bấm nút Hint | Luồng thật | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/dead_no_moves_1.png` | Hết nước đi | sort_die | Lệnh debug | `scripts/main/dialogs/game_dead_toast/game_dead_toast.tscn` |
| `04_Popup/dead_no_moves_2.png` | Hết nước đi | sort_die | Lệnh debug | `scripts/main/dialogs/game_dead_toast/game_dead_toast.tscn` |
| `04_Popup/dialog_avatar_select.png` | Profile / chọn avatar | page-show avatar_select | Mở trực tiếp | `scripts/main/dialogs/avatar_select/avatar_select_dialog.tscn` |
| `04_Popup/dialog_confirm.png` | Xác nhận thoát level | page-show confirm | Mở trực tiếp | `scripts/main/dialogs/confirm/confirm_dialog.tscn` |
| `04_Popup/dialog_privacy.png` | Privacy | page-show privacy | Mở trực tiếp | `scripts/main/dialogs/privacy/privacy_dialog.tscn` |
| `04_Popup/dialog_rank_change.png` | Kết thúc season | page-show rank_change | Mở trực tiếp | `scripts/main/dialogs/rank_change/rank_change_dialog.tscn` |
| `04_Popup/dialog_rank_introduction.png` | Giới thiệu Rank | page-show rank_introduction | Mở trực tiếp | `scripts/main/dialogs/rank_introduction/rank_introduction_dialog.tscn` |
| `04_Popup/dialog_rank_new_season.png` | Season mới | page-show rank_new_season | Mở trực tiếp | `scripts/main/dialogs/rank_new_season/rank_new_season_dialog.tscn` |
| `04_Popup/dialog_rank_season_win.png` | Thắng season | page-show rank_season_win | Mở trực tiếp | `scripts/main/dialogs/rank_season_win/rank_season_win_page.tscn` |
| `04_Popup/dialog_reset_confirm.png` | Xác nhận Reset | page-show reset_confirm | Mở trực tiếp | `scripts/main/dialogs/reset_confirm/reset_confirm_dialog.tscn` |
| `04_Popup/dialog_setting.png` | Settings | page-show setting | Mở trực tiếp | `scripts/main/dialogs/settings/settings_dialog.tscn` |
| `04_Popup/dialog_special_challenge_reward.png` | Thưởng Special Challenge | page-show special_challenge_reward | Mở trực tiếp | `scripts/main/dialogs/special_challenge_reward/special_challenge_reward_dialog.tscn` |
| `04_Popup/dialog_timed_endless_reward.png` | Thưởng Endless | page-show timed_endless_reward | Mở trực tiếp | `scripts/main/dialogs/timed_endless_reward/timed_endless_reward_dialog.tscn` |
| `04_Popup/finish_result.png` | Kết quả thắng | win_round | Lệnh debug | `scripts/main/dialogs/finish/finish_dialog.tscn` |
| `04_Popup/finish_result_fantastic.png` | Kết quả thắng, lời khen khác | thắng level 25 | Lệnh debug | `scripts/main/dialogs/finish/finish_dialog.tscn` |
| `04_Popup/helper_unlock_hint.png` | Mở khóa helper hint | prop_unlock_preview hint | Lệnh debug | `scripts/main/dialogs/prop_unlock/prop_unlock_dialog.tscn` |
| `04_Popup/helper_unlock_rope.png` | Mở khóa helper rope | prop_unlock_preview rope | Lệnh debug | `scripts/main/dialogs/prop_unlock/prop_unlock_dialog.tscn` |
| `04_Popup/helper_unlock_undo.png` | Mở khóa helper undo | prop_unlock_preview undo | Lệnh debug | `scripts/main/dialogs/prop_unlock/prop_unlock_dialog.tscn` |
| `04_Popup/rank_finish_climb.png` | Rank cuối ván, tăng hạng | thắng level 25 | Lệnh debug | `scripts/main/pages/rank_game_finish/rank_game_finish_page.tscn` |
| `04_Popup/rank_finish_continue.png` | Rank cuối ván, nút Continue | win_round | Lệnh debug | `scripts/main/pages/rank_game_finish/rank_game_finish_page.tscn` |
| `04_Popup/rank_finish_enter.png` | Rank cuối ván, đang vào | win_round | Lệnh debug | `scripts/main/pages/rank_game_finish/rank_game_finish_page.tscn` |
| `04_Popup/streak_12.png` | Popup Streak 12 | streak_popup_1 12 | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/streak_3.png` | Popup Streak 3 | streak_popup_1 3 | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/streak_7.png` | Popup Streak 7 | streak_popup_1 7 | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/win_motion_01.png` | Thắng: xu bay | win_round | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `04_Popup/win_motion_02.png` | Thắng: vật phẩm rank bay | win_round | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_bonus_1.png` | Banner Bonus Level, khung 1 | bonus_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_bonus_2.png` | Banner Bonus Level, khung 2 | bonus_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_challenge_1.png` | Banner Challenge, khung 1 | challenge_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_challenge_2.png` | Banner Challenge, khung 2 | challenge_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_combo_fullscreen_fx_1.png` | Combo toàn màn, khung 1 | combo_fullscreen_fx | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_combo_fullscreen_fx_2.png` | Combo toàn màn, khung 2 | combo_fullscreen_fx | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_combo_preview_1.png` | Chữ Combo, khung 1 | combo_preview | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_combo_preview_2.png` | Chữ Combo, khung 2 | combo_preview | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_good_luck_1.png` | Chữ Good Luck, khung 1 | good_luck | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_good_luck_2.png` | Chữ Good Luck, khung 2 | good_luck | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_hard_1.png` | Banner Hard, khung 1 | hard_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_hard_2.png` | Banner Hard, khung 2 | hard_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_smart_move_1.png` | Chữ Smart Move, khung 1 | smart_move | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_smart_move_2.png` | Chữ Smart Move, khung 2 | smart_move | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_streak_1.png` | Banner Streak, khung 1 | streak_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_streak_2.png` | Banner Streak, khung 2 | streak_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_streak_trophy_1.png` | Cúp Streak đang vào, khung 1 | vào level khi đang có streak | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_streak_trophy_2.png` | Cúp Streak đang vào, khung 2 | vào level khi đang có streak | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_super_hard_1.png` | Banner Super Hard, khung 1 | super_hard_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/banner_super_hard_2.png` | Banner Super Hard, khung 2 | super_hard_banner | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/guide_hidden.png` | Hướng dẫn hidden | mở game với save đang ở level 7 | Luồng thật | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/guide_locked_rope.png` | Hướng dẫn locked rope | vào level sau bonus_level | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `05_Banner/guide_sunlight_ice.png` | Hướng dẫn Sunlight / băng | sunlight_pot_level | Lệnh debug | `scripts/main/pages/game/juice_game_page.tscn` |
| `06_Meta/daily_checkin_1.png` | Daily Check-in, vào màn | daily_checkin_preview | Lệnh debug | `scripts/main/dialogs/daily_first_win_checkin/daily_first_win_checkin_dialog.tscn` |
| `06_Meta/daily_checkin_2.png` | Daily Check-in, đang mở quà | daily_checkin_preview | Lệnh debug | `scripts/main/dialogs/daily_first_win_checkin/daily_first_win_checkin_dialog.tscn` |
| `06_Meta/daily_checkin_3.png` | Daily Check-in, nhận xu | daily_checkin_preview | Lệnh debug | `scripts/main/dialogs/daily_first_win_checkin/daily_first_win_checkin_dialog.tscn` |
| `06_Meta/daily_checkin_4.png` | Daily Check-in, hoàn tất | daily_checkin_preview | Lệnh debug | `scripts/main/dialogs/daily_first_win_checkin/daily_first_win_checkin_dialog.tscn` |
| `06_Meta/new_scene_unlock.png` | Mở scene mới | thắng level 25 | Lệnh debug | `scripts/gameplay/outer_loop/view/new_scene_page.tscn` |
| `06_Meta/rank_page.png` | Trang Rank | page-show rank | Mở trực tiếp | `scripts/main/pages/rank/rank_page.tscn` |

## Chưa lấy được

- Màn chơi Endless: game ngừng phản hồi khi mở bằng `juice_endless` (thử 2 lần). Chỉ có popup thưởng Endless.
- Popup Finish Ad Reward và lớp Loading: mở trực tiếp chỉ ra màn trống.
- Hướng dẫn bàn tay ở level 1.
- Băng kiểu chặn ghép (blockConnection) và Container đóng băng.
- Thua do hết giờ, shop, banner quảng cáo.
- Animation: chỉ có vài khung tĩnh, không có video.
