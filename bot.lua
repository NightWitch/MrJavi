redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('botadminset') then
		return true
	else
   		print("\n\27[32m  لازمه کارکرد صحیح ، فرامین و امورات مدیریتی ربات تبلیغ گر <<\n                    تعریف کاربری به عنوان مدیر است\n\27[34m                   ایدی خود را به عنوان مدیر وارد کنید\n\27[32m    شما می توانید از ربات زیر شناسه عددی خود را بدست اورید\n\27[34m        ربات:       @id_ProBot")
    	print("\n\27[32m >> Tabchi Bot need a fullaccess user (ADMIN)\n\27[34m Imput Your ID as the ADMIN\n\27[32m You can get your ID of this bot\n\27[34m                 @id_ProBot")
    	print("\n\27[36m                      : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
    	local admin=io.read()
		redis:del("botadmin")
    	redis:sadd("botadmin", admin)
		redis:set('botadminset',true)
    	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
	end
end
function get_bot (i, naji)
	function bot_info (i, naji)
		redis:set("botid",naji.id_)
		if naji.first_name_ then
			redis:set("botfname",naji.first_name_)
		end
		if naji.last_name_ then
			redis:set("botlanme",naji.last_name_)
		end
		redis:set("botnum",naji.phone_number_)
		return naji.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-.lua")()
	send(chat_id, msg_id, "<i>با موفقیت انجام شد.</i>")
end
function is_naji(msg)
    local var = false
	local hash = 'botadmin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, naji)
	if naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botmaxjoin", tonumber(Time), true)
	else
		redis:srem("botgoodlinks", i.link)
		redis:sadd("botsavedlinks", i.link)
	end
end
function process_link(i, naji)
	if (naji.is_group_ or naji.is_supergroup_channel_) then
		redis:srem("botwaitelinks", i.link)
		redis:sadd("botgoodlinks", i.link)
	elseif naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botmaxlink", tonumber(Time), true)
	else
		redis:srem("botwaitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("botalllinks", link) then
				redis:sadd("botwaitelinks", link)
				redis:sadd("botalllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("botall", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("botusers", id)
			redis:sadd("botall", id)
		elseif Id:match("^-100") then
			redis:sadd("botsupergroups", id)
			redis:sadd("botall", id)
		else
			redis:sadd("botgroups", id)
			redis:sadd("botall", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("botall", id) then
		if Id:match("^(%d+)$") then
			redis:srem("botusers", id)
			redis:srem("botall", id)
		elseif Id:match("^-100") then
			redis:srem("botsupergroups", id)
			redis:srem("botall", id)
		else
			redis:srem("botgroups", id)
			redis:srem("botall", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
redis:set("botstart", true)
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if not redis:get("botmaxlink") then
			if redis:scard("botwaitelinks") ~= 0 then
				local links = redis:smembers("botwaitelinks")
				for x,y in ipairs(links) do
					if x == 6 then redis:setex("botmaxlink", 65, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if not redis:get("botmaxjoin") then
			if redis:scard("botgoodlinks") ~= 0 then
				local links = redis:smembers("botgoodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 2 then redis:setex("botmaxjoin", 65, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("botid") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "3⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			local txt = os.date("<i>پیام ارسال شده از تلگرام در تاریخ 🗓</i><code> %Y-%m-%d </code><i>🗓 و ساعت ⏰</i><code> %X </code><i>⏰ (به وقت سرور)</i>")
			for k,v in ipairs(redis:smembers('botadmin')) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("botall", msg.chat_id_) then
				redis:sadd("botusers", msg.chat_id_)
				redis:sadd("botall", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("botlink") then
				find_link(text)
			end
			if is_naji(msg) then
				find_link(text)
				if text:match("^(حذف لینک) (.*)$") then
					local matches = text:match("^حذف لینک (.*)$")
					if matches == "عضویت" then
						redis:del("botgoodlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت پاکسازی شد.")
					elseif matches == "تایید" then
						redis:del("botwaitelinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار تایید پاکسازی شد.")
					elseif matches == "ذخیره شده" then
						redis:del("botsavedlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده پاکسازی شد.")
					end
				elseif text:match("^(حذف کلی لینک) (.*)$") then
					local matches = text:match("^حذف کلی لینک (.*)$")
					if matches == "عضویت" then
						local list = redis:smembers("botgoodlinks")
						for i, v in ipairs(list) do
							redis:srem("botalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت بطورکلی پاکسازی شد.")
						redis:del("botgoodlinks")
					elseif matches == "تایید" then
						local list = redis:smembers("botwaitelinks")
						for i, v in ipairs(list) do
							redis:srem("botalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار تایید بطورکلی پاکسازی شد.")
						redis:del("botwaitelinks")
					elseif matches == "ذخیره شده" then
						local list = redis:smembers("botsavedlinks")
						for i, v in ipairs(list) do
							redis:srem("botalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده بطورکلی پاکسازی شد.")
						redis:del("botsavedlinks")
					end
				elseif text:match("^(توقف) (.*)$") then
					local matches = text:match("^توقف (.*)$")
					if matches == "عضویت" then	
						redis:set("botmaxjoin", true)
						redis:set("botoffjoin", true)
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خودکار متوقف شد.")
					elseif matches == "تایید لینک" then	
						redis:set("botmaxlink", true)
						redis:set("botofflink", true)
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک در های در انتظار متوقف شد.")
					elseif matches == "شناسایی لینک" then	
						redis:del("botlink")
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی لینک متوقف شد.")
					elseif matches == "افزودن مخاطب" then	
						redis:del("botsavecontacts")
						return send(msg.chat_id_, msg.id_, "فرایند افزودن خودکار مخاطبین به اشتراک گذاشته شده متوقف شد.")
					end
				elseif text:match("^(شروع) (.*)$") then
					local matches = text:match("^شروع (.*)$")
					if matches == "عضویت" then	
						redis:del("botmaxjoin")
						redis:del("botoffjoin")
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خودکار فعال شد.")
					elseif matches == "تایید لینک" then	
						redis:del("botmaxlink")
						redis:del("botofflink")
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک های در انتظار فعال شد.")
					elseif matches == "شناسایی لینک" then	
						redis:set("botlink", true)
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی لینک فعال شد.")
					elseif matches == "افزودن مخاطب" then	
						redis:set("botsavecontacts", true)
						return send(msg.chat_id_, msg.id_, "فرایند افزودن خودکار مخاطبین به اشتراک  گذاشته شده فعال شد.")
					end
elseif text:match("^(حداکثر گروه) (%d+)$") then
     local matches = text:match("%d+")
     redis:set('botmaxgroups', tonumber(matches))
     return send(msg.chat_id_, msg.id_, "از این پس ربات در  "..matches.." گروه عضو میشود😉")
    elseif text:match("^(حداقل اعضا) (%d+)$") then
     local matches = text:match("%d+")
     redis:set('botmaxgpmmbr', tonumber(matches))
     return send(msg.chat_id_, msg.id_, "از این پس ربات در گروه هایی که  "..matches.." عضو دارند،عضو میشود😁")
    elseif text:match("^(حذف حداکثر گروه)$") then
     redis:del('botmaxgroups')
     return send(msg.chat_id_, msg.id_, "تعیین حد مجاز گروه نادیده گرفته شد.😉")
    elseif text:match("^(حذف حداقل اعضا)$") then
     redis:del('botmaxgpmmbr')
     return send(msg.chat_id_, msg.id_, "تعیین حد مجاز اعضای گروه نادیده گرفته شد.")
				elseif text:match("^(افزودن مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botadmin', matches) then
						return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر در حال حاضر مدیر است.</i>")
					elseif redis:sismember('botmod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					else
						redis:sadd('botadmin', matches)
						redis:sadd('botmod', matches)
						return send(msg.chat_id_, msg.id_, "<i>مقام کاربر به مدیر ارتقا یافت</i>")
					end
				elseif text:match("^(افزودن مدیرکل) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botmod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					end
					if redis:sismember('botmod', matches) then
						redis:srem("botmod",matches)
						redis:sadd('botadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "مقام کاربر به مدیریت کل ارتقا یافت .")
					elseif redis:sismember('botadmin',matches) then
						return send(msg.chat_id_, msg.id_, 'درحال حاضر مدیر هستند.')
					else
						redis:sadd('botadmin', matches)
						redis:sadd('botadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "کاربر به مقام مدیرکل منصوب شد.")
					end
				elseif text:match("^(حذف مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botmod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('botadmin', msg.sender_user_id_)
								redis:srem('botmod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "شما دیگر مدیر نیستید.")
						end
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					end
					if redis:sismember('botadmin', matches) then
						if  redis:sismember('botadmin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "شما نمی توانید مدیری که به شما مقام داده را عزل کنید.")
						end
						redis:srem('botadmin', matches)
						redis:srem('botmod', matches)
						return send(msg.chat_id_, msg.id_, "کاربر از مقام مدیریت خلع شد.")
					end
					return send(msg.chat_id_, msg.id_, "کاربر مورد نظر مدیر نمی باشد.")
				elseif text:match("^(تازه سازی ربات)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>مشخصات فردی ربات بروز شد.</i>")
				elseif text:match("ریپورت") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 178220800,
						chat_id_ = 178220800,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^(/reload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^بروزرسانی ربات$") then
					io.popen("git fetch --all && git reset --hard origin/persian && git pull origin persian && chmod +x bot"):read("*all")
					local text,ok = io.open("bot.lua",'r'):read('*a'):gsub("BOT%-ID",)
					io.open("bot-.lua",'w'):write(text):close()
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^همگام سازی با تبچی$") then
					local botid =  - 1
					redis:sunionstore("botall","tabchi:"..tostring(botid)..":all")
					redis:sunionstore("botusers","tabchi:"..tostring(botid)..":pvis")
					redis:sunionstore("botgroups","tabchi:"..tostring(botid)..":groups")
					redis:sunionstore("botsupergroups","tabchi:"..tostring(botid)..":channels")
					redis:sunionstore("botsavedlinks","tabchi:"..tostring(botid)..":savedlinks")
					return send(msg.chat_id_, msg.id_, "<b>همگام سازی اطلاعات با تبچی شماره</b><code> "..tostring(botid).." </code><b>انجام شد.</b>")
				elseif text:match("^(لیست) (.*)$") then
					local matches = text:match("^لیست (.*)$")
					local naji
					if matches == "مخاطبین" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count_
							local text = "مخاطبین : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("bot_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "bot_contacts.txt"},
								caption_ = "مخاطبین تبلیغ‌گر شماره "}
							}, dl_cb, nil)
							return io.popen("rm -rf bot_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "پاسخ های خودکار" then
						local text = "<i>لیست پاسخ های خودکار :</i>\n\n"
						local answers = redis:smembers("botanswerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("botanswers", v)) .. "\n"
						end
						if redis:scard('botanswerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "مسدود" then
						naji = "botblockedusers"
					elseif matches == "شخصی" then
						naji = "botusers"
					elseif matches == "گروه" then
						naji = "botgroups"
					elseif matches == "سوپرگروه" then
						naji = "botsupergroups"
					elseif matches == "لینک" then
						naji = "botsavedlinks"
					elseif matches == "مدیر" then
						naji = "botadmin"
					else
						return true
					end
					local list =  redis:smembers(naji)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(naji)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(naji)..".txt"},
						caption_ = "لیست "..tostring(matches).." های تبلیغ گر شماره "}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(naji)..".txt"):read("*all")
				elseif text:match("^(وضعیت مشاهده) (.*)$") then
					local matches = text:match("^وضعیت مشاهده (.*)$")
					if matches == "روشن" then
						redis:set("botmarkread", true)
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام ها  >>  خوانده شده ✔️✔️\n</i><code>(تیک دوم فعال)</code>")
					elseif matches == "خاموش" then
						redis:del("botmarkread")
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام ها  >>  خوانده نشده ✔️\n</i><code>(بدون تیک دوم)</code>")
					end 
				elseif text:match("^(افزودن با پیام) (.*)$") then
					local matches = text:match("^افزودن با پیام (.*)$")
					if matches == "روشن" then
						redis:set("botaddmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب فعال شد</i>")
					elseif matches == "خاموش" then
						redis:del("botaddmsg")
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب غیرفعال شد</i>")
					end
				elseif text:match("^(افزودن با شماره) (.*)$") then
					local matches = text:match("افزودن با شماره (.*)$")
					if matches == "روشن" then
						redis:set("botaddcontact", true)
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره هنگام افزودن مخاطب فعال شد</i>")
					elseif matches == "خاموش" then
						redis:del("botaddcontact")
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره هنگام افزودن مخاطب غیرفعال شد</i>")
					end
				elseif text:match("^(تنظیم پیام افزودن مخاطب) (.*)") then
					local matches = text:match("^تنظیم پیام افزودن مخاطب (.*)")
					redis:set("botaddmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب ثبت  شد </i>:\n🔹 "..matches.." 🔹")
				elseif text:match('^(تنظیم جواب) "(.*)" (.*)') then
					local txt, answer = text:match('^تنظیم جواب "(.*)" (.*)')
					redis:hset("botanswers", txt, answer)
					redis:sadd("botanswerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(txt) .. "<i> | تنظیم شد به :</i>\n" .. tostring(answer))
				elseif text:match("^(حذف جواب) (.*)") then
					local matches = text:match("^حذف جواب (.*)")
					redis:hdel("botanswers", matches)
					redis:srem("botanswerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(matches) .. "<i> | از لیست جواب های خودکار پاک شد.</i>")
				elseif text:match("^(پاسخگوی خودکار) (.*)$") then
					local matches = text:match("^پاسخگوی خودکار (.*)$")
					if matches == "روشن" then
						redis:set("botautoanswer", true)
						return send(msg.chat_id_, 0, "<i>پاسخگویی خودکار تبلیغ گر فعال شد</i>")
					elseif matches == "خاموش" then
						redis:del("botautoanswer")
						return send(msg.chat_id_, 0, "<i>حالت پاسخگویی خودکار تبلیغ گر غیر فعال شد.</i>")
					end
				elseif text:match("^(تازه سازی)$")then
					local list = {redis:smembers("botsupergroups"),redis:smembers("botgroups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
						redis:set("botcontacts", naji.total_count_)
					end, nil)
					for i, v in ipairs(list) do
							for a, b in ipairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,naji)
									if  naji.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>تازه‌سازی آمار تبلیغ‌گر شماره </i><code>  </code> با موفقیت انجام شد.")
				elseif text:match("^(وضعیت)$") then
					local s =  redis:get("botoffjoin") and 0 or redis:get("botmaxjoin") and redis:ttl("botmaxjoin") or 0
					local ss = redis:get("botofflink") and 0 or redis:get("botmaxlink") and redis:ttl("botmaxlink") or 0
local msgadd = redis:get("botaddmsg") and "🌕" or "🌑"
     local numadd = redis:get("botaddcontact") and "🌕" or "🌑"
     local txtadd = redis:get("botaddmsgtext") or  "ادت کردم عشقم پیوی نقطه بذار😋"
     local autoanswer = redis:get("botautoanswer") and "🌕" or "🌑"
     local wlinks = redis:scard("botwaitelinks")
     local glinks = redis:scard("botgoodlinks")
     local links = redis:scard("botsavedlinks")
     local offjoin = redis:get("botoffjoin") and "🌑" or "🌕"
     local offlink = redis:get("botofflink") and "🌑" or "🌕"
     local nlink = redis:get("botlink") and "🌕" or "🌑"
     local contacts = redis:get("botsavecontacts") and "🌕" or "🌑"
     local txt = " ⚙️وضعیت اجرایی تبلیغ‌گر شماره   ⛓\n\n"..tostring(offjoin).."<code> عضویت خودکار </code>🚀\n"..tostring(offlink).."<code> تایید لینک خودکار </code>🚦\n"..tostring(nlink).."<code> تشخیص لینک های عضویت </code>🎯\n"..tostring(contacts).."<code> افزودن خودکار مخاطبین </code>➕\n" .. tostring(autoanswer) .."<code> حالت پاسخگویی خودکار 🗣 </code>\n" .. tostring(numadd) .. "<code> افزودن مخاطب با شماره 📞 </code>\n" .. tostring(msgadd) .. "<code> افزودن مخاطب با پیام📩</code>\n〰〰〰ا〰〰〰\n📄<code> پیام افزودن مخاطب :</code>\n📍 " .. tostring(txtadd) .. " 📍\n〰〰〰ا〰〰〰\n\n<code>💾 لینک های ذخیره شده : </code><b>" .. tostring(links) .. "</b>\n<code>⏰ لینک های در انتظار عضویت : </code><b>" .. tostring(glinks) .. "</b>\n🕖   <b>" .. tostring(s) .. " </b><code>ثانیه تا عضویت مجدد</code>\n<code>⏳ لینک های در انتظار تایید : </code><b>" .. tostring(wlinks) .. "</b>\n🕑️   <b>" .. tostring(ss) .. " </b><code>زمان باقی مانده تا تایید لینک مجدد</code>\n\n 🌚Edited By: @MrJavi "					
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(امار)$") or text:match("^(آمار)$") then
					local gps = redis:scard("botgroups")
					local sgps = redis:scard("botsupergroups")
					local usrs = redis:scard("botusers")
					local links = redis:scard("botsavedlinks")
					local glinks = redis:scard("botgoodlinks")
					local wlinks = redis:scard("botwaitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
					redis:set("botcontacts", naji.total_count_)
					end, nil)
					local contacts = redis:get("botcontacts")
					local text = [[
آمار تبلیغ گر شماره ی: 📊
          
👤 پی وی ها :
<b>]] .. tostring(usrs) .. [[</b>
👥 گروهای عادی: 
<b>]] .. tostring(gps) .. [[</b>
💎 سوپر گروه ها :
<b>]] .. tostring(sgps) .. [[</b>
📞 مخاطبین : 
<b>]] .. tostring(contacts)..[[</b>
💾لینک های ذخیره شده :
<b>]] .. tostring(links)..[[</b>
 🌚Edited By:@MrJavi]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^(ارسال به) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^ارسال به (.*)$")
					local naji
					if matches:match("^(خصوصی)") then
						naji = "botusers"
					elseif matches:match("^(گروه)$") then
						naji = "botgroups"
elseif matches:match("^(همه)$") then
						naji = "botall"
					elseif matches:match("^(سوپرگروه)$") then
						naji = "botsupergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id_
					for i, v in pairs(list) do
						tdcli_function({
							ID = "ForwardMessages",
							chat_id_ = v,
							from_chat_id_ = msg.chat_id_,
							message_ids_ = {[0] = id},
							disable_notification_ = 1,
							from_background_ = 1
						}, dl_cb, nil)
					end
					return send(msg.chat_id_, msg.id_, "<i>با موفقیت فرستاده شد</i>")
				elseif text:match("^(ارسال به سوپرگروه) (.*)") then
					local matches = text:match("^ارسال به سوپرگروه (.*)")
					local dir = redis:smembers("botsupergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    			return send(msg.chat_id_, msg.id_, "<i>با موفقیت فرستاده شد</i>")
				elseif text:match("^(مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("botblockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر مسدود شد</i>")
				elseif text:match("^(رفع مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("botblockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>مسدودیت کاربر مورد نظر رفع شد.</i>")	
				elseif text:match('^(تنظیم نام) "(.*)" (.*)') then
					local fname, lname = text:match('^تنظیم نام "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>نام جدید با موفقیت ثبت شد.</i>")
				elseif text:match("^(تنظیم نام کاربری) (.*)") then
					local matches = text:match("^تنظیم نام کاربری (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>تلاش برای تنظیم نام کاربری...</i>')
				elseif text:match("^(حذف نام کاربری)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>نام کاربری با موفقیت حذف شد.</i>')
				elseif text:match('^(ارسال کن) "(.*)" (.*)') then
					local id, txt = text:match('^ارسال کن "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>ارسال شد</i>")
				elseif text:match("^(بگو) (.*)") then
					local matches = text:match("^بگو (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(شناسه من)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(ترک کردن) (.*)$") then
					local matches = text:match("^ترک کردن (.*)$") 	
					send(msg.chat_id_, msg.id_, 'تبلیغ‌گر از گروه مورد نظر خارج شد')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(افزودن به همه) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("botgroups"),redis:smembers("botsupergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  50
							}, dl_cb, nil)
						end	
					end
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر به تمام گروه های من دعوت شد</i>")
				elseif (text:match("^(انلاین)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^(راهنما)$") then
					local txt = '💠لیست دستورات و راهنمای <i>سین آپ</i> 🔰انلاین\n🔸اعلام وضعیت <i>سین آپ</i>\n🔺حتی اگر تبلیغ گر دچار محدودیت ارسال پیام(ریپورت چت) شده باشد باید به این پیام واکنش نشان دهد\n🔰/reload\n🔸بارگذاری مجدد ربات\n🔺توصیه میشود بی جهت از این دستور استفاده نکنید\n🔰افزودن مدیرکل (شناسه)\n🔸افزودن مدیرکل جدید با شناسه عددی داده شده\n🔰افزودن مدیر (شناسه)\n🔸افزودن مدیر جدید با شناسه داده شده\n🔺برای حذف مدیران میتوانید بجای کلمه "افزودن" از کلمه "حذف" استفاده کنید\n🔰ترک گروه\n🔸خروج از گروه مورد نظر و حذف آن از اطلاعات گروه ها\n🔰افزودن همه مخاطبین\n🔸افزودن همه مخاطبین و پیوی ها به گروه\n🔰شناسه من\n🔸دریافت شناسه یا آیدی عددی خود\n🔰بگو (متن)\n🔸اکو کردن یا بازگو کردن متن مورد نظر\n🔰ارسال کن "شناسه" متن \n🔸ارسال متن مورد نظر به آیدی کاربر یا گروه مشخص شده\n🔰حداکثر گروه (تعداد)\n🔸تعیین تعداد حداکثر گروه\n🔰حذف حداکثر گروه\n🔸صرف نظر از عضویت در تعداد معینی گروه\n🔺با فعال سازی این بخش ربات فقط در تعداد تعیین شده گروه عضو میشود،مثلا اگر تعداد تعیین شده 500 باشد ربات در 500 گروه عضو میشود\n🔰حداقل اعضا (تعداد)\n🔸عضویت در گروه هایی با حداقل عضو معین شده\n🔰حذف حداقل اعضا\n🔸صرف نظر از عضویت در گروه هایی با تعداد عضو معین شده\n🔺اگر این قابلیت فعال باشد ربات در گروه هایی با اعضایی که تعداد آن مشخص شده عضو میشود، برای مثال اگر حداقل اعضا 200 باشد ربات در گروه هایی که 200 عضو دارد،عضو میشود\n🔰تنظیم نام "نام" فامیل\n🔸تنظیم نام <i>سین آپ</i>🔰تازه سازی ربات\n🔸بروز رسانی اطلاعات شخصی از قبیل نام و نام کاربری\n🔰تنظیم نام کاربری (نام کاربری)\n🔸تغییر نام کاربری ربات به کلمه داده شده\n🔰حذف نام کاربری\n🔸حذف نام کاربری ربات <i>سین آپ</i>\n🔰شروع عضویت/تایید لینک / شناسایی لینک/افزودن مخاطب\n🔸فعال سازی هر یک از فرایند های خواسته شده\n🔰توقف عضویت/تایید لینک/شناسایی لینک/افزودن مخاطب\n🔸غیر فعال سازی فرایند های خواسته شده\n🔰افزودن به شماره روشن / خاموش\n🔸هنگامی که این قابلیت فعال باشد ربات پس از مشاهده کانتکت شماره خود را به اشتراک میگذارد\n🔰افزودن با پیام روشن/خاموش\n🔸هنگامی که این قابلیت فعال باشد ربات پس از مشاهده کانتکت شماره خود را به اشتراک میگذارد\n🔰تنظیم پیام افزودن مخاطب (متن مورد نظر)\n🔸تنظیم متن داده شده بعنوان پاسخی برای به اشتراک گذاشتن شماره توسط دیگران\n🔰لیست مخاطبین/خصوصی/گروه/سوپرگروه/پاسخ های خودکاری/لینک/مدیر\n🔸دریافت لیست هر یک از مقادیر داده شده بصورت فایل یا پرونده متنی\n🔰مسدودیت (شناسه)\n🔸بلاک یا مسدود کردن شخص دارنده شناسه داده شده از ربات\n🔰رفع مسدودیت (شناسه)\n🔸آنبلاک یا آزاد کردن شخص دارنده شناسه داده شده از ربات \n🔰وضعیت مشاهده روشن/خاموش\n🔸تغییر وضعیت خوانده شدن پیام ها توسط ربات(تیک دوم)\n🔰امار\n🔸دریافت مشخصات وضعیت ربات تبلیغ گر\n🔰وضعیت\n🔸دریافت وضعیت ربات <i>سین آپ</i>\n🔰تازه سازی \n🔸تازه سازی آمار <i>سین آپ</i>\n🔰ارسال به همه/خصوصی/گروه/سوپرگروه\n🔸ارسال پیام جواب داده شده(ریپلی شده) به موارد بالا\n🔰ارسال به سوپرگروه (متن)\n🔸ارسال متن داده شده به سوپرگروه\n🔰تنظیم جواب "سوال" جواب\n🔸تنظیم جواب مورد نظر برای سوال خواسته شده\n🔰حذف جواب "سوال"\n🔸حذف جواب مربوط به سوال مورد نظر\n🔰پاسخگوی خودکار روشن/خاموش\n🔸فعال یا غیر فعال سازی پاسخ به سوال داده شده\n🔰حذف لینک عضویت/تایید/ذخیره شده\n🔸حذف لیست لینک فرایند مشخص شده\n🔰حذف کلی لینک عضویت/تایید/ذخیره شده\n🔸حذف تمامی لینک ها\n🔰افزودن به همه (شناسه) \n🔸افزودن کاربر به همه گروه ها و سوپر گروه ها با ایدی داده شده\n🔰ترک کردن (شناسه)\n🔸ترک گروه با ایدی داده شده\n🔰همگام سازی با تبچی\n🔸همگام سازی اطلاعات ربات تبچی با ربات های ما قبل خود\n🌚 Creator:@MrJavi\n🔰 Channel:@CMSecurityCH'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(ترک کردن)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(افزودن همه مخاطبین)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, naji)
							local users, count = redis:smembers("botusers"), naji.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = naji.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "<i>در حال افزودن مخاطبین به گروه ...</i>")
					end
				end
			end
			if redis:sismember("botanswerslist", text) then
				if redis:get("botautoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("botanswers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("botsavecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("botaddedcontacts",id) then
				redis:sadd("botaddedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("botaddcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("botfname")
					local lnasme = redis:get("botlname") or ""
					local num = redis:get("botnum")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("botaddmsg") then
				local answer = redis:get("botaddmsgtext") or "اددی گلم خصوصی پیام بده"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("botlink"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("botmarkread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
		tdcli_function ({
			ID = "GetChats",
			offset_order_ = 9223372036854775807,
			offset_chat_id_ = 0,
			limit_ = 1000
		}, dl_cb, nil)
	end
end
