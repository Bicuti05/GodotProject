import json,csv,collections,importlib.util,io,contextlib
from openpyxl import Workbook
from openpyxl.styles import Font,PatternFill,Alignment,Border,Side
from openpyxl.utils import get_column_letter as L
ab=json.load(open('/tmp/claude-0/ab_rows.json'))
G_LV='Level & độ khó'; G_SP='Vị trí đặc biệt'; G_RULE='Luật chơi'; G_AID='Hỗ trợ thao tác & hướng dẫn'; G_ECO='Thưởng, kinh tế, IQ, xếp hạng, thống kê'; G_AD='Quảng cáo'; G_UI='Giao diện, âm thanh, rung, khởi động'
D={
'difficulty_rule':(G_LV,'Luật lên/xuống mức người chơi','0 = luật gốc: lên mức khi thắng sạch liên tiếp N màn, xuống khi quá nửa N màn gần nhất không sạch','1 = lv4, lv5 phải có 4 màn không sạch trong 5 màn gần nhất mới xuống; 2 = lên mức khi quá nửa số màn gần nhất là thắng sạch (không cần liên tiếp). Chỉ áp dụng cho người đã từng lên mức 3'),
'daily_first_round_downgrade':(G_LV,'Hạ bản ở các màn đầu mỗi ngày','0 = đối chứng, không hạ','1 / 2 / 3 = 1 / 2 / 3 màn mới đầu tiên trong ngày dùng bản của mức thấp hơn; thắng sạch ở các màn đó không tính để lên mức'),
'coin_bonus_level_rule':(G_SP,'Màn nhân đôi xu (rule bonus của Sort Streak, theo ngày)','0 = mặc định (đối chứng)','1 = mọi màn, cứ 3 màn thường 1 màn, tối đa 4 mỗi ngày; 2 = màn Hard, cứ 2 màn Hard 1 màn, tối đa 3 mỗi ngày'),
'bonus_level2.0':(G_SP,'Bonus Level 2.0','0 = bản 1.0 gốc','1 = bản 2.0'),
'mainline_timed_endless':(G_SP,'Màn Endless có giới hạn thời gian chèn vào tuyến chính','0 = giữ nguyên tuyến chính','1 = từ màn 30, cứ 10 màn chèn 1 màn Endless (30, 40, 50…)'),
'special_level2.0':(G_SP,'Kho level Special / Challenge','0 = kho cũ','1 = kho mới'),
'special_theme':(G_SP,'Giao diện bàn chơi cho màn Special','0 = mặc định','1 = giao diện Special; 2 = Special và thêm các màn 12, 22, 32…'),
'sunlight_gameplay':(G_SP,'Băng + ánh nắng (chậu đóng băng)','0 = tắt','1 = bật'),
'allow_root_swapping':(G_RULE,'Hoán đổi gốc dây','0 = luật gốc (không hoán đổi)','1 = bật từ màn 1; 2 = bật từ màn 1 và còn thao tác được sau khi thua'),
'mystery_auto_unlock':(G_RULE,'Tự mở mọi hoa ẩn khi tới chậu cuối','0 = không, giữ như hiện tại','1 = có'),
'sort_reveal_memory':(G_RULE,'Hoàn tác với hoa ẩn','0 = hoa ẩn bị che lại','1 = giữ nguyên trạng thái đã mở'),
'sort_dead_return_to_safe_state':(G_RULE,'Khi thua, quay về bàn an toàn','0 = hoàn tác từng bước','1 = lùi nhiều bước một lần'),
'complete_prop':(G_RULE,'Hoàn thành một cột: vị trí chơi lại và vật phẩm','0 = baseline','1 = chơi lại dời lên; 2 = dời lên cộng vật phẩm; 3 = như 2 và nút chơi lại nền trắng chữ xanh'),
'same_color_highlight':(G_AID,'Hoa cùng màu "thở" khi kéo','0 = không','1 = có'),
'location_judge':(G_AID,'Cách xét vị trí thả','0 = cũ','1 = ngưỡng 1,2 / 0,8'),
'long_link':(G_AID,'Hiện biểu tượng sau 10 giây suy nghĩ','0 = tắt','1 = bật'),
'error_animation':(G_AID,'Hiệu ứng khi nước đi sai','0 = bản cũ','1 = bản mới (hai bông và gợi ý chỗ trống)'),
'revive_prompt_style':(G_AID,'Kiểu nhắc hồi sinh khi thua','0 = mặc định','1 = thiết kế lại'),
'sort_rope_capacity_knots':(G_AID,'Hiện chữ sức chứa dưới dây','0 = ẩn','1 = hiện'),
'new_guide':(G_AID,'Hướng dẫn người chơi mới','0 = bản gốc','1 = thanh luật hiện thường trực; 2 = dạy 4 mục tiêu'),
'level_target_coins':(G_ECO,'Xu thưởng cho mỗi chậu','0 = 10 xu mỗi chậu','1 = 5 xu mỗi chậu'),
'daily_first_win_checkin':(G_ECO,'Điểm danh thắng đầu ngày','0 = tắt','1 = 300/500/1000 xu; 2 = 0/800/1000 xu'),
'finish_ad_reward2.0':(G_ECO,'Quảng cáo thưởng ở trang kết thúc màn Hard / Super Hard','0 = tắt','1 = bật'),
'IQ_data':(G_ECO,'Số liệu IQ ở trang kết thúc','0 = thống kê cũ','1 = thay số bước; 2 = thay chuỗi thắng'),
'iq_score_boost':(G_ECO,'Tăng điểm IQ','0 = như hiện tại','1 = hạng A giữ khoảng cách tối thiểu; 2 = hạng S không cần khoảng cách'),
'game_data2.0':(G_ECO,'Số liệu thống kê và banner chuỗi thắng','0 = bảng cũ','1 = bảng mới'),
'streak_banner':(G_ECO,'Banner chuỗi thắng','0 = bản gốc','1 = bản mới có chặn; 2 = bản mới không chặn'),
'rank_unlock_timing':(G_ECO,'Thời điểm mở bảng xếp hạng','0 = sau màn 20','1 = sau màn 15; 2 = sau màn 10'),
'rank_update':(G_ECO,'Thuật toán bảng xếp hạng','0 = bản cũ','1 = 24 giờ; 2 = 48 giờ (có hiệu lực với sự kiện mới)'),
'rank_collectible_fx':(G_ECO,'Vật thu thập trên bảng xếp hạng','0 = hoa gốc','1 = hộp quà theo số mục tiêu; 2 = hộp quà theo độ dài cột'),
'banner_unlock_level':(G_AD,'Màn mở banner quảng cáo','Dự phòng của client: 1.000.000.000 (tắt)','Số nguyên n: banner bật khi màn thường > n'),
'inter_cd_by_day':(G_AD,'Thời gian chờ giữa hai quảng cáo xen kẽ theo ngày','Dự phòng của client: [0_inf:60] (60 giây)','Chuỗi cấu hình theo khoảng ngày'),
'inter_protect_by_day':(G_AD,'Số màn được bảo vệ không hiện quảng cáo xen kẽ theo ngày','Dự phòng của client: [1_inf:0]','Chuỗi cấu hình theo khoảng ngày'),
'inter_unlock_level':(G_AD,'Số màn mở quảng cáo xen kẽ','Dự phòng của client: 10','Số nguyên n'),
'bgm_test':(G_UI,'Nhạc nền','0 = không','1, 2, 3 = bgm 1, 2, 3'),
'christmas_theme':(G_UI,'Giao diện Giáng sinh','0 = hiện tại','1 = giao diện Giáng sinh'),
'cold_start_optimization':(G_UI,'Tối ưu khởi động nguội','0 = không','1 = có (hiệu lực khi khởi động lại)'),
'combo_freq':(G_UI,'Thời điểm combo 2.0','0 = thu chậu liên tục','1 = thu chậu cách quãng'),
'combo_fullscreen_fx':(G_UI,'Hiệu ứng toàn màn hình của combo','0 = bản gốc','1 = ruy băng ba giai đoạn'),
'combo_sfx_style':(G_UI,'Âm thanh combo','0 = mặc định','1 = bộ 1'),
'complete_sfx_style':(G_UI,'Âm thanh hoàn thành màn','0 = mặc định','1 = giai điệu ngắn gọn; 2 = giai điệu phong phú'),
'game_enter_haptic':(G_UI,'Rung khi vào màn chơi','0 = không','1 = có'),
'hard_level_banner_style':(G_UI,'Kiểu banner màn Hard','0 = bản gốc','1 = hoạt ảnh mới; 2 = banner hoa'),
'logo_design':(G_UI,'Thiết kế logo splash','0 = bản gốc','1 = bản mới'),
'main_btn':(G_UI,'Hiệu ứng nút chính ở Home','0 = bản gốc','1 = quét sáng và sao'),
'same_color_flower_merge_sfx':(G_UI,'Âm thanh gộp hoa cùng màu','0 = mặc định','1 = bộ 1; 2 = bộ 2'),
'shake_v2':(G_UI,'Rung phiên bản 2','0 = đối chứng','1 = kiểu 1; 2 = kiểu 2'),
'splash':(G_UI,'Tối ưu splash','0 = bản gốc','1 = trích dẫn theo quốc gia'),
'splash_min_display_seconds':(G_UI,'Thời gian hiện splash tối thiểu','0 = 2 giây','1 = 3,4 giây; 2 = 3,8 giây; 3 = 4,2 giây'),
}
missing=[r['key'] for r in ab if r['key'] not in D]; assert not missing,missing
spec=importlib.util.spec_from_file_location('lr','/tmp/claude-0/ladder_reuse.py'); lr=importlib.util.module_from_spec(spec)
with contextlib.redirect_stdout(io.StringIO()): spec.loader.exec_module(lr)
T={'goc':lr.tabs['goc'],'easy':lr.tabs['easy_promotion']}
def need(tab,a,b,slack):
    best=10**9
    for ua in ([a]+([a+1] if slack and a<5 else [])):
        for ub in ([b]+([b+1] if slack and b<5 else [])):
            best=min(best,0 if ua==ub else tab[(ua,ub)])
    return best
TW={k:min(T['goc'][k],T['easy'][k]) for k in T['goc']}
ss=list(csv.DictReader(open('/tmp/claude-0/kit/ss_levels.csv',encoding='utf-8-sig')))
SS={}; BOARD={}
for r in ss:
    lv=int(r['level'])
    if lv<=200: SS[(r['set'],lv)]=float(r['summaryScore']); BOARD[(r['set'],lv)]=r['board_id']
A={}
for r in csv.DictReader(open('/tmp/claude-0/ab/new_level_report.csv',encoding='utf-8-sig')): A[int(r['man'])]=float(r['diem_muc_tieu'])
sets=['default','lv2','lv3','lv4','lv5']
def sc(s,l): return SS.get((s,l), SS[('default',l)])
def special(l):
    out=[]
    if l==1: out.append('Hướng dẫn cố định của dev (bản B không sinh)')
    if l>=13 and (l-13)%10==0: out.append('Bonus')
    if l>=17 and (l-17)%10==0: out.append('Challenge (bị thay lúc chơi)')
    if l>=30 and (l-30)%10==0: out.append('Endless (bị thay lúc chơi)')
    return ' + '.join(out)
def req(l):
    o=[]
    if l>=13 and (l-13)%10==0: o.append('Có ít nhất 1 màu chỉ có đúng 1 chậu trong cả level (cả dây initial và incoming, tính cả chậu trên dây khóa)')
    if l>=17 and (l-17)%10==0: o.append('Vẫn sinh level thường (dev chưa có cơ chế Challenge)')
    if l>=30 and (l-30)%10==0: o.append('Vẫn sinh level thường (dev chưa có cơ chế Endless)')
    if l==1: o.append('Bản B: không sinh, dev dùng level hướng dẫn cố định')
    if 2<=l<=5: o.append('Màn 2–5: giống nhau ở cả 5 bộ B, không dùng lại ở màn khác')
    return '; '.join(o)
def groups(l):
    g=collections.defaultdict(list)
    for s in sets:
        g[BOARD.get((s,l)) or BOARD[('default',l)]].append(s)
    return ' | '.join('+'.join(v) for v in g.values())
F='Arial'; HF=Font(name=F,bold=True,color='FFFFFF'); HFILL=PatternFill('solid',fgColor='305496'); N=Font(name=F); B=Font(name=F,bold=True)
thin=Side(style='thin',color='BFBFBF'); BD=Border(top=thin,bottom=thin,left=thin,right=thin)
WRAP=Alignment(wrap_text=True,vertical='top')
wb=Workbook()
def sheet(name,header,rows,widths,first=False):
    ws=wb.active if first else wb.create_sheet()
    ws.title=name; ws.append(header)
    for r in rows: ws.append(r)
    for c in ws[1]: c.font=HF; c.fill=HFILL; c.alignment=Alignment(wrap_text=True,vertical='center'); c.border=BD
    for row in ws.iter_rows(min_row=2):
        for c in row: c.font=N; c.alignment=WRAP; c.border=BD
    for i,w in enumerate(widths,1): ws.column_dimensions[L(i)].width=w
    ws.freeze_panes='A2'
    return ws
readme=[
['Phạm vi','Tổng hợp các phần A/B (thử nghiệm) trong code Sort Streak ảnh hưởng tới level, độ khó và vị trí màn đặc biệt, để dùng khi sinh và kiểm level Sweet Rope.'],
['Hai bản A/B của Sweet Rope (theo bạn)','Bản A: một bộ level duy nhất, theo đường độ khó mới chốt (bộ trong branch New_Level). Bản B: giống Sort Streak, gồm 5 bộ level bám 5 đường độ khó của Sort Streak: default (cho người chơi chưa có mức hoặc mức 1), lv2, lv3, lv4, lv5, có luật lên/xuống mức.'],
['Phương án đang dùng','Phương án gốc (nhóm đối chứng) của mọi A/B: difficulty_rule = 0, daily_first_round_downgrade = 0, content level experiment = default, allow_root_swapping = 0, mystery_auto_unlock = 0, sort_reveal_memory = 0, sunlight_gameplay = 0, mainline_timed_endless = 0, special_level2.0 = 0. Hạ bản sau 4 lần chơi lại KHÔNG phải A/B, luôn bật.'],
['Bonus','Rule bonus Sweet Rope đã chốt (GD, 26/11): cố định ở màn 13, 23, 33… (từ 13, cách 10). Level cần có ít nhất một màu chỉ có đúng 1 chậu. Bonus KHÔNG ghi vào file level. Các rule bonus theo ngày của Sort Streak (coin_bonus_level_rule, bonus_level2.0) không dùng.'],
['Nguồn','Code Sort Streak trong repo (scripts/data/abtest, level_manager.gd, user_level_ladder.gd) và ghi chú GD trong GD_Lazy/Level Difficulty/Generated/Curve_Analysis_Kit/sweet_rope/Note_Dev_Bonus_Level.md. Mô tả A/B được dịch từ nhãn trong code (tiếng Trung).'],
['Các sheet','1) AB ảnh hưởng level, 2) Tất cả AB, 3) Tái sử dụng level, 4) Vị trí và điểm mục tiêu.'],
]
sheet('Đọc trước',['Mục','Nội dung'],readme,[34,120],first=True)
extra=[
 [G_LV,'(Không phải A/B) Hạ bản sau 4 lần chơi lại','Hằng số REPEAT_RESTART_DOWNGRADE_COUNT = 4 trong level_manager.gd','Luôn bật cho mọi nhóm','Chơi lại cùng một màn 4 lần liên tiếp thì màn đó đổi sang bản của mức thấp hơn gần nhất có bố cục khác','Người chơi mức cao có thể thấy bản mức thấp: rủi ro gặp lại level đã chơi nếu level đó được dùng ở màn khác','Đang dùng (không tắt được bằng A/B)','Nếu Sweet Rope bỏ cơ chế này, bảng tái sử dụng rộng hơn (sheet 3)'],
 [G_LV,'Content level experiments (khóa bắt đầu bằng "content_sg||level||")','Thử nghiệm nội dung level từ server: mỗi thử nghiệm phủ một khoảng màn (start–end); giá trị "default" là đối chứng','default','Giá trị khác thay (vá) nội dung level trong khoảng màn đó','Nếu bật, level người chơi thấy có thể khác bộ level đã sinh','Đang dùng: default','Cần biết Sweet Rope có dùng không'],
 [G_LV,'Kênh chương (flow domain): baseline hay experiment','Game chọn kênh dữ liệu chương: baseline hoặc experiment (mặc định)','Tùy domain SDK; client dự phòng là experiment','Hai kênh có thể chứa hai bộ level khác nhau (hai file builtin chapter_default / chapter_baseline)','Có thể là cơ chế dev dùng để chia bản A và bản B của bạn. Mình chưa xác nhận','Chưa xác định','Cần dev xác nhận cách chia A/B cho Sweet Rope'],
]
EFF={'difficulty_rule':'Đổi số màn thắng tối thiểu để đổi bộ, nên đổi luật tái sử dụng level (sheet 3)',
'daily_first_round_downgrade':'Người chơi mức cao có thể thấy bản mức thấp ở màn đầu ngày: rủi ro lặp level',
'coin_bonus_level_rule':'Sort Streak chọn màn bonus theo số màn đã chơi trong ngày. Sweet Rope bỏ, thay bằng rule cố định 13, 23, 33…',
'bonus_level2.0':'Chế độ bonus; Sweet Rope theo ghi chú GD: heo vàng cố định',
'mainline_timed_endless':'Endless thay level ở màn 30, 40, 50… lúc chơi. Dev chưa có cơ chế: vẫn cần level thường',
'special_level2.0':'Kho level Special/Challenge (17, 27…). Dev chưa có: vẫn cần level thường',
'special_theme':'Chỉ đổi giao diện bàn, không đổi dữ liệu level',
'sunlight_gameplay':'Băng + ánh nắng. Sweet Rope hiện bỏ qua Ice (32 level trong màn 42–200)',
'allow_root_swapping':'Đổi luật chơi nên đổi độ khó thật. Bot và solver của mình đo ở luật gốc (tắt)',
'mystery_auto_unlock':'Đổi độ khó của màn có hoa ẩn','sort_reveal_memory':'Đổi độ khó của màn có hoa ẩn khi hoàn tác',
'sort_dead_return_to_safe_state':'Đổi cách phục hồi khi thua','complete_prop':'Đổi vị trí chơi lại và vật phẩm sau khi hoàn thành một cột'}
rows1=list(extra)
for r in ab:
    g,d,ctrl,oth=D[r['key']]
    if g in (G_LV,G_SP,G_RULE):
        nxt={'difficulty_rule':'Tính lại bảng tái sử dụng với giá trị 1, 2 (đã có sẵn ở sheet 3, bảng C và D)','daily_first_round_downgrade':'Tính lại bảng tái sử dụng khi bật hạ bản đầu ngày'}.get(r['key'],'')
        rows1.append([g,r['key'],d,ctrl,oth,EFF[r['key']],'Gốc (đối chứng)',nxt])
sheet('AB ảnh hưởng level',['Nhóm','Khóa A/B','Ý nghĩa','Giá trị gốc (đối chứng)','Các giá trị khác','Tác động tới level / độ khó / vị trí','Đang dùng','Cần kiểm lần sau'],rows1,[24,34,48,34,48,52,22,40])
order=[G_LV,G_SP,G_RULE,G_AID,G_ECO,G_AD,G_UI]
rows2=[[D[r['key']][0],r['key'],D[r['key']][1],D[r['key']][2],D[r['key']][3],r['file']] for g in order for r in ab if D[r['key']][0]==g]
sheet('Tất cả AB',['Nhóm','Khóa A/B','Ý nghĩa','Giá trị gốc (đối chứng)','Các giá trị khác','File cấu hình'],rows2,[30,34,52,40,56,60])
names=['default (mức 0–1)','lv2','lv3','lv4','lv5']
ws3=wb.create_sheet('Tái sử dụng level')
def grid(tab,slack,mode):
    out=[]
    for a in range(1,6):
        row=[names[a-1]]
        for b in range(1,6):
            if a==b: row.append('x')
            elif mode=='min': row.append(tab[(a,b)])
            else:
                m=need(tab,a,b,slack); row.append('x' if m==0 else m-1)
        out.append(row)
    return out
def block(title,note,tab,slack,mode,start):
    ws3.cell(start,1,title).font=B
    ws3.cell(start+1,1,note).font=Font(name=F,italic=True,color='595959')
    for j,h in enumerate(['Bộ ở màn nhỏ hơn \\ bộ ở màn lớn hơn']+names,1):
        c=ws3.cell(start+2,j,h); c.font=HF; c.fill=HFILL; c.alignment=Alignment(wrap_text=True); c.border=BD
    for i,row in enumerate(grid(tab,slack,mode)):
        for j,v in enumerate(row,1):
            c=ws3.cell(start+3+i,j,v); c.font=N; c.border=BD; c.alignment=Alignment(horizontal='center' if j>1 else 'left')
    return start+10
r=1
ws3.cell(r,1,'Khi nào được dùng lại cùng một level ở hai màn khác nhau?').font=Font(name=F,bold=True,size=13); r+=1
for t in ['Mỗi người chơi chỉ gặp mỗi màn một lần, nhưng có thể đổi bộ giữa chừng. Level X ở màn s1 (bộ a) và màn s2 > s1 (bộ b) chỉ an toàn nếu người chơi không thể ở bộ a tại s1 rồi ở bộ b tại s2.',
          'Số màn thắng giữa hai lần gặp là s2 − s1. An toàn khi s2 − s1 NHỎ HƠN số màn thắng tối thiểu để đổi bộ. Số tối thiểu tính trên mọi trạng thái xuất phát: người chơi có thể đã có sẵn chuỗi thắng khi tới s1, nên lần lên mức đầu chỉ cần 1 màn thắng.',
          'Cùng một bộ ở hai màn khác nhau: không bao giờ an toàn. Cùng một màn ở các bộ khác nhau: luôn an toàn (như Sort Streak đang làm). Màn 1–5 gặp bởi mọi người chơi: không dùng lại ở màn khác.',
          'Hạ bản (chơi lại 4 lần, và màn đầu ngày nếu bật A/B) có thể phát bản mức thấp hơn cho người chơi mức cao. Bảng tính theo trường hợp hạ đúng 1 bậc. Nếu nhiều bộ dùng chung một level ở cùng một màn, hạ bản có thể bỏ qua nhiều bậc; mình sẽ kiểm chính xác khi có level thật.']:
    c=ws3.cell(r,1,t); c.font=N; c.alignment=WRAP; ws3.merge_cells(start_row=r,start_column=1,end_row=r,end_column=6); ws3.row_dimensions[r].height=58; r+=1
r+=1
r=block('A. ĐANG DÙNG: luật gốc, có hạ bản sau 4 lần chơi lại (số màn chênh tối đa để dùng lại an toàn)','Số trong ô = chênh màn tối đa để dùng lại an toàn; 0 hoặc x = không dùng lại ở màn khác. Ví dụ lv2 ở màn 20 và lv5 ở màn 25 (chênh 5) an toàn, ở màn 26 (chênh 6) thì không. Ví dụ của bạn (màn 20 bộ lv2, màn 24 bộ lv5, chênh 4) an toàn ở bảng A, B, D và chỉ không an toàn ở bảng C.',T['goc'],1,'safe',r)
r=block('B. Luật gốc, không có hạ bản','Dùng khi Sweet Rope bỏ cơ chế hạ bản sau 4 lần chơi lại.',T['goc'],0,'safe',r)
r=block('C. Để kiểm lần sau: A/B "lên mức dễ hơn" (difficulty_rule = 2), có hạ bản','Số liệu xấu nhất khi bật A/B này.',TW,1,'safe',r)
r=block('D. Để kiểm lần sau: A/B "lên mức dễ hơn", không hạ bản','Số liệu xấu nhất khi bật A/B này.',TW,0,'safe',r)
r=block('E. Số màn thắng tối thiểu để đi từ bộ này sang bộ kia (luật gốc)','Hàng = bộ xuất phát, cột = bộ đến, tính cả lên và xuống mức.',T['goc'],0,'min',r)
ws3.column_dimensions['A'].width=46
for j in range(2,7): ws3.column_dimensions[L(j)].width=18
hdr=['Màn','Chương','Màn trong chương','Vị trí trong nhịp 5','Loại','Màn đặc biệt','Yêu cầu thêm cho level','Điểm mục tiêu bản A (bộ duy nhất)','B: default','B: lv2','B: lv3','B: lv4','B: lv5','Số bố cục khác nhau (Sort Streak)','Bộ dùng chung bố cục trong Sort Streak']
rows4=[]
for l in range(1,201):
    rows4.append([l,(l-1)//25+1,(l-1)%25+1,(l-1)%5+1,'Hard' if l%5==0 else 'Normal',special(l),req(l),A[l]]+[round(sc(s,l),1) for s in sets]+[len({BOARD.get((s,l)) or BOARD[('default',l)] for s in sets}),groups(l)])
sheet('Vị trí và điểm mục tiêu',hdr,rows4,[7,9,11,11,9,34,64,14,10,10,10,10,10,14,40])
wb.save('/tmp/claude-0/ab/SweetRope_AB_tong_hop.xlsx')
print('saved; total distinct boards =',sum(r[13] for r in rows4))
