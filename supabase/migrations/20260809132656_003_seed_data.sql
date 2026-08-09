-- Seed events from the static events.js data.
-- This migration is idempotent: ON CONFLICT DO NOTHING on event key.
DO $$
DECLARE
  _org_id uuid;
BEGIN
  -- Insert organizer for bepnho
  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Bếp Nhỏ', '@bepnho.saigon', 'Minh nấu cho người lạ từ 2021, bắt đầu bằng vài cái bàn trong ga-ra. Mỗi tối một thực đơn, đi chợ Bà Chiểu lúc sáu giờ sáng.', 2021, 47, true)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_bepnho', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Cơm Nhà Mai', '@comnhamai', 'Mai dọn bữa tối trên sân thượng nhà mình, nấu kiểu cơm nhà miền Trung. Tám chỗ, không hơn.', 2023, 12, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_comnha', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Bàn Dài', '@bandai.supper', 'Một cái bàn dài, những người chưa từng gặp. Bàn Dài dọn bữa cho người lạ ngồi cạnh nhau từ 2022.', 2022, 31, true)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_bandai', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Phở Khuya', '@phokhuya', 'Tùng bán phở lúc nửa đêm cho người đi làm ca muộn và người không ngủ được. Mười hai ghế nhựa, một nồi nước.', 2024, 8, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_phokhuya', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Vườn Sau', '@vuonsau.collective', 'Nhóm bạn nấu ăn trong khu vườn sau nhà ở Gò Vấp. Rau hái tại vườn, mưa thì dời vô hiên.', 2025, 3, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_vuonsau', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Rue Miche L''Édition', '@ruemiche', 'Cửa hàng và không gian sự kiện của các nhà thiết kế Việt. L''Édition là chuỗi buổi diễn giới thiệu bộ sưu tập mới, tổ chức tại xưởng.', 2020, 9, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_orbit', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('AEIE Studios', '@aeie.studios', 'Studio thời trang ở Thảo Điền, thành lập 2018. Tinh thần: bình thường hóa những điều khác thường.', 2018, 22, true)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_aeie', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Fanci Club', '@fanci.club', 'Thương hiệu của Duy Trần, cùng quỹ đạo sáng tạo với AEIE. Đồ may đo, thử tại chỗ.', 2023, 6, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_fanci', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Compound Garment', '@compound.garment', 'Streetwear địa phương, Quận 1. Drop giới hạn, thường bán trên sân thượng lúc chiều muộn.', 2021, 15, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_compound', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Mãi Mãi', '@maimai.mag', 'Tạp chí về chất liệu và nghề thủ công Việt. Mãi bám rễ nơi ta đến, mãi vươn về nơi ta tới.', 2024, 4, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_motlop', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Nguyen Art Foundation', '@nguyenartfoundation', 'Quỹ nghệ thuật đương đại tại HCMC, sưu tập và trưng bày nghệ sĩ Việt trong và ngoài nước.', 2019, 18, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_vungtrang', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Galerie Quỳnh', '@galeriequynh', 'Phòng tranh đương đại lâu đời của thành phố, chuyên nghệ sĩ Việt và quốc tế.', 2015, 60, true)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_sonmai', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Lâm', '@khongnguoi', 'Lâm chụp thành phố không người trong sáu năm, đi bộ lúc năm giờ sáng. Đây là triển lãm cá nhân đầu tiên.', 2026, 1, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_khongnguoi', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Zone Publishing', '@zone.publishing', 'Nhà làm zine và sách nhỏ, tổ chức các buổi nói chuyện về nghề in và giấy.', 2022, 9, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_noigiay', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Phòng 302', '@phong302', 'Không gian nghệ thuật trong một căn hộ tập thể cũ ở Quận 5. Mỗi kỳ một nhóm nghệ sĩ.', 2023, 7, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_phong302', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Yentown', '@yentown.saigon', 'Sân chơi phức hợp nghệ thuật ở Quận 1. Chiều Chậm là chuỗi buổi DJ thư giãn cuối tuần.', 2021, 33, true)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_chieucham', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Gác', '@jazzogac', 'Gác gỗ hai mươi chỗ trên một con hẻm Quận 1. Jazz mộc, không micro, mỗi tuần một nhóm.', 2020, 52, true)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_jazzgac', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Băng Cối', '@bangcoi.club', 'Câu lạc bộ nghe nhạc từ băng cối qua dàn loa cổ. Không điện thoại trong phòng nghe.', 2022, 14, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_bangcoi', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('OBJoff', '@objoff', 'Tập thể nhạc điện tử thử nghiệm với dàn máy modular. Không set nào lặp lại.', 2023, 11, false)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_modular', _org_id::text, true);

  INSERT INTO organizers (name, ig_handle, bio, hosting_since, event_count, verified)
  VALUES ('Nhà Piano', '@nhapiano', 'Một căn phòng, một cây đàn. Nhà Piano tổ chức recital muộn cho tối đa mười hai người.', 2019, 26, true)
  ON CONFLICT DO NOTHING RETURNING id INTO _org_id;
  PERFORM set_config('goc.org_pianomuon', _org_id::text, true);

END $$;

-- Now insert events using a second DO block
DO $$
DECLARE
  _org_id uuid;
BEGIN
  -- bepnho
  SELECT id INTO _org_id FROM organizers WHERE name = 'Bếp Nhỏ' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('bepnho', _org_id, 'Bếp Nhỏ №12', 'supper', 'Supper club', 'Mười bốn chỗ. Một ga-ra cải tạo ở Bình Thạnh. Minh nấu món gì chợ sáng có.', '5 món ▪︎ rượu gạo ▪︎ cà phê', '900.000₫', 90000000, false, 14, 3, 'Bình Thạnh ▪︎ 2,1 km từ bạn ▪︎ Thứ Bảy, 11 tháng 7 ▪︎ 19:00', 'Bình Thạnh', '2,1 km', 'Th 7, 11.07', 'Thứ Bảy, 11 tháng 7', '19:00', '2026-07-11', '19:00', 'open', false, 'Chào bạn, mình là Minh. Cứ hỏi thoải mái nhé.', '/photos/DSCF4423.jpg', jsonb_build_array('/photos/DSCF4423.jpg','/photos/DSCF5481.jpg','/photos/DSCF6107.jpg','/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg')::jsonb, jsonb_build_array('/photos/DSCF4423.jpg','/photos/DSCF5481.jpg','/photos/DSCF6107.jpg','/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg')::jsonb, 'Minh, @bepnho.saigon', 'Minh', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- comnha
  SELECT id INTO _org_id FROM organizers WHERE name = 'Cơm Nhà Mai' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('comnha', _org_id, 'Cơm Nhà Mai', 'supper', 'Supper club', 'Tám chỗ quanh bếp than trên sân thượng. Mai nướng cá theo mùa.', '4 món ▪︎ trà ▪︎ tráng miệng', '700.000₫', 70000000, false, 8, 5, 'Quận 3 ▪︎ 3,4 km từ bạn ▪︎ Thứ Năm, 9 tháng 7 ▪︎ 19:30', 'Quận 3', '3,4 km', 'Th 5, 09.07', 'Thứ Năm, 9 tháng 7', '19:30', '2026-07-09', '19:30', 'open', false, 'Mai đây. Nhà có cầu thang hơi dốc, báo trước nếu cần hỗ trợ nhé.', '/photos/DSCF5481.jpg', jsonb_build_array('/photos/DSCF5481.jpg','/photos/DSCF6107.jpg','/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg')::jsonb, jsonb_build_array('/photos/DSCF5481.jpg','/photos/DSCF6107.jpg','/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg')::jsonb, 'Mai, @comnhamai', 'Mai', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- bandai (cancelled)
  SELECT id INTO _org_id FROM organizers WHERE name = 'Bàn Dài' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('bandai', _org_id, 'Bàn Dài №4', 'supper', 'Supper club', 'Một bàn, mười sáu người lạ, sáu món. Không ai rời bàn trước món cuối.', '6 món ▪︎ rượu vang ▪︎ nước lọc đầy bình', '1.200.000₫', 120000000, false, 16, 2, 'Thảo Điền ▪︎ 6,1 km từ bạn ▪︎ Thứ Sáu, 10 tháng 7 ▪︎ 19:00', 'Thảo Điền', '6,1 km', 'Th 6, 10.07', 'Thứ Sáu, 10 tháng 7', '19:00', '2026-07-10', '19:00', 'cancelled', false, 'Bàn Dài xin chào. Ăn chay hay dị ứng gì cứ nhắn.', '/photos/DSCF6107.jpg', jsonb_build_array('/photos/DSCF6107.jpg','/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg')::jsonb, jsonb_build_array('/photos/DSCF6107.jpg','/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg')::jsonb, 'Bàn Dài', 'Bàn Dài', 'concrete', 5, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- phokhuya (ended)
  SELECT id INTO _org_id FROM organizers WHERE name = 'Phở Khuya' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('phokhuya', _org_id, 'Phở Khuya', 'supper', 'Supper club', 'Phở lúc mười một giờ đêm, nước dùng hầm từ trưa. Mười hai ghế nhựa.', '1 tô ▪︎ quẩy ▪︎ trà đá', '350.000₫', 35000000, false, 12, 9, 'Quận 4 ▪︎ 2,8 km từ bạn ▪︎ Thứ Bảy, 11 tháng 7 ▪︎ 23:00', 'Quận 4', '2,8 km', 'Th 7, 11.07', 'Thứ Bảy, 11 tháng 7', '23:00', '2026-07-11', '23:00', 'ended', false, 'Tùng đây. Đến trễ 15 phút là hết nước béo nha.', '/photos/DSCF5891.jpg', jsonb_build_array('/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg')::jsonb, jsonb_build_array('/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg')::jsonb, 'Tùng, @phokhuya', 'Tùng', 'concrete', NULL, 10)
  ON CONFLICT (key) DO NOTHING;

  -- vuonsau
  SELECT id INTO _org_id FROM organizers WHERE name = 'Vườn Sau' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('vuonsau', _org_id, 'Vườn Sau', 'supper', 'Supper club', 'Bữa tối trong vườn sau nhà, đèn dây và mưa thì dời vô hiên.', '5 món ▪︎ cocktail mở màn', '850.000₫', 85000000, false, 6, 6, 'Gò Vấp ▪︎ 7,2 km từ bạn ▪︎ Chủ Nhật, 12 tháng 7 ▪︎ 18:00', 'Gò Vấp', '7,2 km', 'CN, 12.07', 'Chủ Nhật, 12 tháng 7', '18:00', '2026-07-12', '18:00', 'open', false, 'Vườn Sau chào bạn. Tối có muỗi, mình có xịt sẵn.', '/photos/DSCF2836.jpg', jsonb_build_array('/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg')::jsonb, jsonb_build_array('/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg')::jsonb, 'Vườn Sau', 'Vườn Sau', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- orbit
  SELECT id INTO _org_id FROM organizers WHERE name = 'Rue Miche L''Édition' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('orbit', _org_id, 'ORBIT: Afterlight', 'fashion', 'Thời trang', 'Sàn thép, sân khấu tròn, khói. Bốn mươi phút, không nghỉ. Bộ sưu tập mới của L''Édition, lần đầu ra mắt ngoài cửa hàng.', 'Welcome drink ▪︎ zine L''Édition №4', '400.000₫', 40000000, false, 40, 23, 'Quận 1 ▪︎ 4,8 km từ bạn ▪︎ Thứ Sáu, 10 tháng 7 ▪︎ 20:00', 'Quận 1', '4,8 km', 'Th 6, 10.07', 'Thứ Sáu, 10 tháng 7', '20:00', '2026-07-10', '20:00', 'open', false, 'Rue Miche đây. Có gì cần hỏi về buổi diễn không?', '/photos/DSCF4627.jpg', jsonb_build_array('/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg')::jsonb, jsonb_build_array('/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg')::jsonb, 'Rue Miche L''Édition', 'Rue Miche', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- aeie
  SELECT id INTO _org_id FROM organizers WHERE name = 'AEIE Studios' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('aeie', _org_id, 'AEIE: Mở Xưởng', 'fashion', 'Thời trang', 'Xưởng may mở cửa một buổi chiều. Xem rập, vải, và những mẫu chưa bao giờ bán.', 'Trà ▪︎ tour xưởng 30 phút', '300.000₫', 30000000, false, 25, 18, 'Thảo Điền ▪︎ 6,3 km từ bạn ▪︎ Thứ Bảy, 11 tháng 7 ▪︎ 16:00', 'Thảo Điền', '6,3 km', 'Th 7, 11.07', 'Thứ Bảy, 11 tháng 7', '16:00', '2026-07-11', '16:00', 'open', false, 'AEIE đây, hỏi gì cứ nhắn.', '/photos/DSCF2503.jpg', jsonb_build_array('/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg')::jsonb, jsonb_build_array('/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg')::jsonb, 'AEIE Studios', 'AEIE', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- fanci (sold out)
  SELECT id INTO _org_id FROM organizers WHERE name = 'Fanci Club' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('fanci', _org_id, 'Fanci: Đêm Thử Đồ', 'fashion', 'Thời trang', 'Thử đồ như một buổi tiệc. Gương, đèn, và một stylist mỗi ba khách.', 'Stylist ▪︎ đồ uống ▪︎ chỉnh sửa tại chỗ', '500.000₫', 50000000, false, 16, 0, 'Quận 1 ▪︎ 5,0 km từ bạn ▪︎ Thứ Năm, 9 tháng 7 ▪︎ 19:00', 'Quận 1', '5,0 km', 'Th 5, 09.07', 'Thứ Năm, 9 tháng 7', '19:00', '2026-07-09', '19:00', 'sold_out', false, 'Fanci nghe. Size ngoài bảng cứ hỏi, xưởng may được.', '/photos/DSCF4254.jpg', jsonb_build_array('/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg')::jsonb, jsonb_build_array('/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg')::jsonb, 'Fanci Club', 'Fanci', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- compound
  SELECT id INTO _org_id FROM organizers WHERE name = 'Compound Garment' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('compound', _org_id, 'Compound: Sân Thượng', 'fashion', 'Thời trang', 'Drop mới trên sân thượng, mặc thử dưới trời chiều. Bán hết là thôi.', 'Vào cửa ▪︎ sticker pack', '250.000₫', 25000000, false, 50, 31, 'Quận 1 ▪︎ 4,6 km từ bạn ▪︎ Chủ Nhật, 12 tháng 7 ▪︎ 17:00', 'Quận 1', '4,6 km', 'CN, 12.07', 'Chủ Nhật, 12 tháng 7', '17:00', '2026-07-12', '17:00', 'open', false, 'Compound đây. Drop giới hạn, mỗi người hai món thôi nha.', '/photos/DSCF5796.jpg', jsonb_build_array('/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg')::jsonb, jsonb_build_array('/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg')::jsonb, 'Compound Garment', 'Compound', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- motlop (ended)
  SELECT id INTO _org_id FROM organizers WHERE name = 'Mãi Mãi' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('motlop', _org_id, 'Chỉ Một Lớp', 'fashion', 'Thời trang', 'Một đêm về vải: bốn nhà thiết kế, một chất liệu, bốn cách cắt.', 'Talk 40 phút ▪︎ đồ uống', '600.000₫', 60000000, false, 12, 8, 'Quận 3 ▪︎ 3,9 km từ bạn ▪︎ Thứ Tư, 8 tháng 7 ▪︎ 19:30', 'Quận 3', '3,9 km', 'Th 4, 08.07', 'Thứ Tư, 8 tháng 7', '19:30', '2026-07-08', '19:30', 'ended', false, 'Mãi Mãi đây. Buổi này nói tiếng Việt, có phụ đề Anh.', '/photos/DSCF5780.jpg', jsonb_build_array('/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg')::jsonb, jsonb_build_array('/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg')::jsonb, 'Mãi Mãi × góc', 'Mãi Mãi', 'concrete', NULL, 74)
  ON CONFLICT (key) DO NOTHING;

  -- vungtrang
  SELECT id INTO _org_id FROM organizers WHERE name = 'Nguyen Art Foundation' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('vungtrang', _org_id, 'Vùng Trắng', 'gallery', 'Phòng tranh', 'Sáu họa sĩ, một màu. Triển lãm nhóm về sự trống, mở cửa một đêm trước công chúng.', 'Catalogue ▪︎ trò chuyện với giám tuyển', '150.000₫', 15000000, false, 50, 41, 'Thảo Điền ▪︎ 6,3 km từ bạn ▪︎ Chủ Nhật, 12 tháng 7 ▪︎ 18:00', 'Thảo Điền', '6,3 km', 'CN, 12.07', 'Chủ Nhật, 12 tháng 7', '18:00', '2026-07-12', '18:00', 'open', false, 'Xin chào. Đây là kênh của Nguyen Art Foundation.', '/photos/DSCF2539.jpg', jsonb_build_array('/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg')::jsonb, jsonb_build_array('/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg')::jsonb, 'Nguyen Art Foundation', 'NAF', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- sonmai
  SELECT id INTO _org_id FROM organizers WHERE name = 'Galerie Quỳnh' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('sonmai', _org_id, 'Đối Thoại Sơn Mài', 'gallery', 'Phòng tranh', 'Hai thế hệ sơn mài treo đối diện nhau. Người xem đứng giữa.', 'Vào cửa ▪︎ tài liệu triển lãm', '100.000₫', 10000000, false, 50, 26, 'Quận 1 ▪︎ 4,4 km từ bạn ▪︎ Thứ Sáu, 10 tháng 7 ▪︎ 18:30', 'Quận 1', '4,4 km', 'Th 6, 10.07', 'Thứ Sáu, 10 tháng 7', '18:30', '2026-07-10', '18:30', 'open', false, 'Chào bạn, Galerie Quỳnh đây.', '/photos/DSCF4517.jpg', jsonb_build_array('/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg')::jsonb, jsonb_build_array('/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg','/photos/DSCF4196.jpg')::jsonb, 'Galerie Quỳnh', 'Quỳnh', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- khongnguoi
  SELECT id INTO _org_id FROM organizers WHERE name = 'Lâm' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('khongnguoi', _org_id, 'Ảnh Không Người', 'gallery', 'Phòng tranh', 'Ba mươi tấm ảnh thành phố, không một bóng người. Chụp trong sáu năm.', 'Vào cửa ▪︎ print khổ nhỏ', '120.000₫', 12000000, false, 50, 35, 'Quận 3 ▪︎ 3,2 km từ bạn ▪︎ Thứ Bảy, 11 tháng 7 ▪︎ 17:00', 'Quận 3', '3,2 km', 'Th 7, 11.07', 'Thứ Bảy, 11 tháng 7', '17:00', '2026-07-11', '17:00', 'open', false, 'Lâm đây. Ảnh không bán tại chỗ, chỉ đặt trước.', '/photos/DSCF6366.jpg', jsonb_build_array('/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg')::jsonb, jsonb_build_array('/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg','/photos/DSCF4196.jpg','/photos/DSCF6368.jpg')::jsonb, 'Lâm, @khongnguoi', 'Lâm', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- noigiay
  SELECT id INTO _org_id FROM organizers WHERE name = 'Zone Publishing' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('noigiay', _org_id, 'Nói Chuyện: Giấy', 'gallery', 'Phòng tranh', 'Một giờ về giấy dó với người làm giấy đời thứ ba. Có mẫu để sờ.', 'Talk ▪︎ trà ▪︎ mẫu giấy mang về', '80.000₫', 8000000, false, 50, 20, 'Quận 1 ▪︎ 4,9 km từ bạn ▪︎ Thứ Tư, 8 tháng 7 ▪︎ 19:00', 'Quận 1', '4,9 km', 'Th 4, 08.07', 'Thứ Tư, 8 tháng 7', '19:00', '2026-07-08', '19:00', 'open', false, 'Zone đây. Buổi talk có ghi hình, ngồi hàng sau nếu ngại.', '/photos/DSCF4223.jpg', jsonb_build_array('/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg')::jsonb, jsonb_build_array('/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg','/photos/DSCF4196.jpg','/photos/DSCF6368.jpg','/photos/DSCF2237.jpg')::jsonb, 'Zone Publishing', 'Zone', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- phong302
  SELECT id INTO _org_id FROM organizers WHERE name = 'Phòng 302' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('phong302', _org_id, 'Phòng 302', 'gallery', 'Phòng tranh', 'Triển lãm trong căn hộ tập thể cũ. Mỗi phòng một tác giả, giữ nguyên đồ đạc.', 'Vào cửa theo khung giờ', '150.000₫', 15000000, false, 50, 14, 'Quận 5 ▪︎ 5,7 km từ bạn ▪︎ Chủ Nhật, 12 tháng 7 ▪︎ 15:00', 'Quận 5', '5,7 km', 'CN, 12.07', 'Chủ Nhật, 12 tháng 7', '15:00', '2026-07-12', '15:00', 'open', false, '302 đây. Lên cầu thang bộ, tầng ba, cửa xanh.', '/photos/DSCF5542.jpg', jsonb_build_array('/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg')::jsonb, jsonb_build_array('/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg','/photos/DSCF4196.jpg','/photos/DSCF6368.jpg','/photos/DSCF2237.jpg','/photos/DSCF5973.jpg')::jsonb, 'Phòng 302', '302', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- chieucham (free)
  SELECT id INTO _org_id FROM organizers WHERE name = 'Yentown' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('chieucham', _org_id, 'Chiều Chậm', 'music', 'Nhạc', 'Ba DJ, một buổi chiều, không danh sách nhạc định trước. Đến sớm có chỗ ngồi.', 'Vào cửa tự do ▪︎ cà phê tính riêng', 'Miễn phí', 0, true, 60, 58, 'Yentown, Quận 1 ▪︎ 4,5 km từ bạn ▪︎ Chủ Nhật, 12 tháng 7 ▪︎ 15:00', 'Yentown, Quận 1', '4,5 km', 'CN, 12.07', 'Chủ Nhật, 12 tháng 7', '15:00', '2026-07-12', '15:00', 'open', false, 'Yentown nghe đây.', '/photos/DSCF2341.jpg', jsonb_build_array('/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg')::jsonb, jsonb_build_array('/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg','/photos/DSCF4196.jpg','/photos/DSCF6368.jpg','/photos/DSCF2237.jpg','/photos/DSCF5973.jpg','/photos/DSCF4058.jpg')::jsonb, 'Yentown', 'Yentown', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- jazzgac
  SELECT id INTO _org_id FROM organizers WHERE name = 'Gác' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('jazzgac', _org_id, 'Jazz Ở Gác', 'music', 'Nhạc', 'Gác gỗ hai mươi chỗ, kèn không mic. Set hai bắt đầu lúc mười giờ.', '2 set ▪︎ một đồ uống', '250.000₫', 25000000, false, 20, 16, 'Quận 1 ▪︎ 4,7 km từ bạn ▪︎ Thứ Năm, 9 tháng 7 ▪︎ 21:00', 'Quận 1', '4,7 km', 'Th 5, 09.07', 'Thứ Năm, 9 tháng 7', '21:00', '2026-07-09', '21:00', 'open', false, 'Gác đây. Set hai đông hơn, thích yên thì đến set một.', '/photos/DSCF4238.jpg', jsonb_build_array('/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg')::jsonb, jsonb_build_array('/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg','/photos/DSCF4196.jpg','/photos/DSCF6368.jpg','/photos/DSCF2237.jpg','/photos/DSCF5973.jpg','/photos/DSCF4058.jpg','/photos/DSCF4039.jpg')::jsonb, 'Gác, @jazzogac', 'Gác', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- bangcoi
  SELECT id INTO _org_id FROM organizers WHERE name = 'Băng Cối' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('bangcoi', _org_id, 'Băng Cối', 'music', 'Nhạc', 'Nghe nhạc từ băng cối qua dàn loa cũ. Không điện thoại trong phòng nghe.', 'Vào cửa ▪︎ trà nóng', '180.000₫', 18000000, false, 30, 22, 'Quận 3 ▪︎ 3,6 km từ bạn ▪︎ Thứ Sáu, 10 tháng 7 ▪︎ 20:00', 'Quận 3', '3,6 km', 'Th 6, 10.07', 'Thứ Sáu, 10 tháng 7', '20:00', '2026-07-10', '20:00', 'open', false, 'Băng Cối đây. Phòng nghe im lặng tuyệt đối nha.', '/photos/DSCF7257.jpg', jsonb_build_array('/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg')::jsonb, jsonb_build_array('/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg','/photos/DSCF4196.jpg','/photos/DSCF6368.jpg','/photos/DSCF2237.jpg','/photos/DSCF5973.jpg','/photos/DSCF4058.jpg','/photos/DSCF4039.jpg','/photos/DSCF4065.jpg')::jsonb, 'Băng Cối', 'Băng Cối', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- modular
  SELECT id INTO _org_id FROM organizers WHERE name = 'OBJoff' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('modular', _org_id, 'Đêm Modular', 'music', 'Nhạc', 'Bốn nghệ sĩ, bốn dàn máy, nối dây trực tiếp. Không có bài nào lặp lại.', 'Vào cửa ▪︎ earplugs miễn phí', '200.000₫', 20000000, false, 30, 27, 'Quận 4 ▪︎ 3,0 km từ bạn ▪︎ Thứ Bảy, 11 tháng 7 ▪︎ 21:30', 'Quận 4', '3,0 km', 'Th 7, 11.07', 'Thứ Bảy, 11 tháng 7', '21:30', '2026-07-11', '21:30', 'open', false, 'OBJoff đây, tối đó gặp nhé.', '/photos/DSCF6279.jpg', jsonb_build_array('/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg')::jsonb, jsonb_build_array('/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg','/photos/DSCF4196.jpg','/photos/DSCF6368.jpg','/photos/DSCF2237.jpg','/photos/DSCF5973.jpg','/photos/DSCF4058.jpg','/photos/DSCF4039.jpg','/photos/DSCF4065.jpg','/photos/DSCF7752.jpg')::jsonb, 'OBJoff', 'OBJoff', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- pianomuon
  SELECT id INTO _org_id FROM organizers WHERE name = 'Nhà Piano' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('pianomuon', _org_id, 'Piano Muộn', 'music', 'Nhạc', 'Một cây đàn, một người chơi, đèn tắt gần hết. Bốn mươi lăm phút.', '1 set ▪︎ một ly vang', '300.000₫', 30000000, false, 12, 11, 'Quận 1 ▪︎ 5,2 km từ bạn ▪︎ Chủ Nhật, 12 tháng 7 ▪︎ 22:00', 'Quận 1', '5,2 km', 'CN, 12.07', 'Chủ Nhật, 12 tháng 7', '22:00', '2026-07-12', '22:00', 'open', false, 'Nhà Piano chào bạn. Đến trước 21:45 nhé, vào trễ phải chờ hết bài.', '/photos/DSCF4282.jpg', jsonb_build_array('/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg')::jsonb, jsonb_build_array('/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg','/photos/DSCF4880.jpg','/photos/DSCF4488.jpg','/photos/DSCF4889.jpg','/photos/DSCF7202.jpg','/photos/DSCF7039.jpg','/photos/DSCF6022.jpg','/photos/DSCF4207.jpg','/photos/DSCF6837.jpg','/photos/DSCF2438.jpg','/photos/DSCF4864.jpg','/photos/DSCF4196.jpg','/photos/DSCF6368.jpg','/photos/DSCF2237.jpg','/photos/DSCF5973.jpg','/photos/DSCF4058.jpg','/photos/DSCF4039.jpg','/photos/DSCF4065.jpg','/photos/DSCF7752.jpg','/photos/DSCF7609.jpg')::jsonb, 'Nhà Piano', 'Nhà Piano', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- banrieng (invite only)
  SELECT id INTO _org_id FROM organizers WHERE name = 'Bếp Nhỏ' LIMIT 1;
  INSERT INTO events (key, organizer_id, name, cat_key, cat_label, description, included, price_text, price_cents, is_free, capacity, seats_remaining, location, area, km_text, day_short, day_long, time_text, event_date, event_time, status, invite_only, greeting, hero_photo, gallery, org_gallery, host_name, host_short, palette, cancelled_hours_ago, ended_hours_ago)
  VALUES ('banrieng', _org_id, 'Bàn Riêng', 'supper', 'Supper club', 'Sáu chỗ, không đăng công khai. Minh nấu riêng cho vài người quen của người quen.', '7 món ▪︎ rượu vang chọn riêng', '1.500.000₫', 150000000, false, 6, 4, 'Bình Thạnh ▪︎ 2,1 km từ bạn ▪︎ Thứ Tư, 15 tháng 7 ▪︎ 19:30', 'Bình Thạnh', '2,1 km', 'Th 4, 15.07', 'Thứ Tư, 15 tháng 7', '19:30', '2026-07-15', '19:30', 'open', true, 'Bạn được mời vào bàn này. Rủ thêm 1 người cũng được nhé.', '/photos/DSCF4423.jpg', jsonb_build_array('/photos/DSCF4423.jpg','/photos/DSCF5481.jpg','/photos/DSCF6107.jpg','/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg')::jsonb, jsonb_build_array('/photos/DSCF4423.jpg','/photos/DSCF5481.jpg','/photos/DSCF6107.jpg','/photos/DSCF5891.jpg','/photos/DSCF2836.jpg','/photos/DSCF4627.jpg','/photos/DSCF2503.jpg','/photos/DSCF4254.jpg','/photos/DSCF5796.jpg','/photos/DSCF5780.jpg','/photos/DSCF2539.jpg','/photos/DSCF4517.jpg','/photos/DSCF6366.jpg','/photos/DSCF4223.jpg','/photos/DSCF5542.jpg','/photos/DSCF2341.jpg','/photos/DSCF4238.jpg','/photos/DSCF7257.jpg','/photos/DSCF6279.jpg','/photos/DSCF4282.jpg','/photos/DSCF4550.jpg','/photos/DSCF4212.jpg')::jsonb, 'Minh, @bepnho.saigon', 'Minh', 'concrete', NULL, NULL)
  ON CONFLICT (key) DO NOTHING;

  -- Secondary categories (paid placement)
  INSERT INTO event_categories (event_id, cat_key, cat_label, sort_order)
  SELECT id, 'gallery', 'Phòng tranh', 1 FROM events WHERE key = 'motlop'
  ON CONFLICT DO NOTHING;

  INSERT INTO event_categories (event_id, cat_key, cat_label, sort_order)
  SELECT id, 'gallery', 'Phòng tranh', 1 FROM events WHERE key = 'aeie'
  ON CONFLICT DO NOTHING;

  INSERT INTO event_categories (event_id, cat_key, cat_label, sort_order)
  SELECT id, 'supper', 'Supper club', 1 FROM events WHERE key = 'chieucham'
  ON CONFLICT DO NOTHING;

END $$;
