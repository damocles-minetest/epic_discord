
local http = minetest.request_http_api()
local texture_baseurl = minetest.settings:get("epic_discord.texture_baseurl")

if not http or not texture_baseurl then
	return
end

local update_formspec = function(meta)
	local text = meta:get_string("text")
	local texture = meta:get_string("texture")
	meta:set_string("infotext", "Webhook block: '" .. text .. "'")

	meta:set_string("formspec", "size[8,4;]" ..
		-- col 1
		"field[0.2,0.5;8,1;text;Template (use @player and @owner);" .. text .. "]" ..

		-- col 2
		"field[0.2,1.5;8,1;texture;Texture;" .. texture .. "]" ..

		-- col 3
		"field[0.2,2.5;8,1;url;URL (blanked, type to change);]" ..

		-- col 4
		"button_exit[0.1,3.5;8,1;save;Save]" ..
		"")
end

local execute = function(text, texture, webhook_url)
	local data = {
		content = text
	}

	if texture_baseurl and texture and texture  ~= "" then
		data.avatar_url = texture_baseurl .. texture
	end

	local json = minetest.write_json(data)

	-- new rank
	http.fetch({
		url = webhook_url,
		extra_headers = { "Content-Type: application/json" },
		timeout = 5,
		post_data = json
	}, function()
		-- ignore error
	end)
end

minetest.register_node("epic_discord:webhook", {
	description = "Epic discord webhook block",
	tiles = {
		"epic_node_bg.png",
		"epic_node_bg.png",
		"epic_node_bg.png",
		"epic_node_bg.png",
		"epic_node_bg.png",
		"epic_node_bg.png^epic_rss.png",
	},
	paramtype2 = "facedir",
	groups = {cracky=3,oddly_breakable_by_hand=3,epic=1},
	on_rotate = screwdriver.rotate_simple,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("url", "")
		meta:set_string("texture", "")
		meta:set_string("text", "Player @player finished the level 'xyz'!")
		meta:mark_as_private("url")
    update_formspec(meta, pos)
	end,

  on_receive_fields = function(pos, _, fields, sender)
    local meta = minetest.get_meta(pos);

		if not sender or sender:get_player_name() ~= meta:get_string("owner") then
			-- not allowed
			return
		end

    if fields.save then
			if fields.url and fields.url ~= "" then
				-- only update if changed
				meta:set_string("url", fields.url)
				meta:mark_as_private("url")
			end
			meta:set_string("text", fields.text or "Test!")
			meta:set_string("texture", fields.texture or "")
			update_formspec(meta, pos)
    end

  end,

	epic = {
    on_enter = function(_, meta, player, ctx)
			local text = meta:get_string("text")
			local url = meta:get_string("url")
			local owner = meta:get_string("owner")
			local texture = meta:get_string("texture")

			text = text:gsub("@player", player:get_player_name())
			text = text:gsub("@owner", owner)
			execute(text, texture, url)
      ctx.next()
    end
  }
})
