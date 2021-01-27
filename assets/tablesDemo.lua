local disable_indent = false
local CT_Text = 0
local CT_FillButton = 1
local ImGuiTableFlags_SizingMask_ = ImGui.TableFlags_SizingFixedFit | ImGui.TableFlags_SizingFixedSame | ImGui.TableFlags_SizingStretchProp | ImGui.TableFlags_SizingStretchSame

local CT_ShowWidth = 0
local CT_ShortText = 1
local CT_LongText = 2
local CT_Button = 3
local CT_FillButton = 4
local CT_InputText = 5

local flags_1 = ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg
local display_headers = false
local contents_type = CT_Text

local flags_2 = ImGui.TableFlags_SizingStretchSame | ImGui.TableFlags_Resizable | ImGui.TableFlags_BordersOuter | ImGui.TableFlags_BordersV | ImGui.TableFlags_ContextMenuInBody
local flags_3 = ImGui.TableFlags_SizingFixedFit | ImGui.TableFlags_Resizable | ImGui.TableFlags_BordersOuter | ImGui.TableFlags_BordersV | ImGui.TableFlags_ContextMenuInBody
local flags_4 = ImGui.TableFlags_SizingFixedFit | ImGui.TableFlags_RowBg | ImGui.TableFlags_Borders | ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable
local flags_5 = ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable | ImGui.TableFlags_BordersOuter | ImGui.TableFlags_BordersV
local flags_6_1 = ImGui.TableFlags_BordersV
local flags_6_2 = ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg
local flags_7_1 = ImGui.TableFlags_BordersV | ImGui.TableFlags_BordersOuterH | ImGui.TableFlags_RowBg | ImGui.TableFlags_ContextMenuInBody
local cell_padding_x = 0
local cell_padding_y = 0
local show_widget_frame_bg = true
local sizing_policy_flags = { ImGui.TableFlags_SizingFixedFit, ImGui.TableFlags_SizingFixedSame, ImGui.TableFlags_SizingStretchProp, ImGui.TableFlags_SizingStretchSame }
local policies = {
    { Value = ImGuiTableFlags_None,               Name = "Default",                            Tooltip = "Use default sizing policy:\n- ImGuiTableFlags_SizingFixedFit if ScrollX is on or if host window has ImGuiWindowFlags_AlwaysAutoResize.\n- ImGuiTableFlags_SizingStretchSame otherwise." },
    { Value = ImGuiTableFlags_SizingFixedFit,     Name = "ImGuiTableFlags_SizingFixedFit",     Tooltip = "Columns default to _WidthFixed (if resizable) or _WidthAuto (if not resizable), matching contents width." },
    { Value = ImGuiTableFlags_SizingFixedSame,    Name = "ImGuiTableFlags_SizingFixedSame",    Tooltip = "Columns are all the same width, matching the maximum contents width.\nImplicitly disable ImGuiTableFlags_Resizable and enable ImGuiTableFlags_NoKeepColumnsVisible." },
    { Value = ImGuiTableFlags_SizingStretchProp,  Name = "ImGuiTableFlags_SizingStretchProp",  Tooltip = "Columns default to _WidthStretch with weights proportional to their widths." },
    { Value = ImGuiTableFlags_SizingStretchSame,  Name = "ImGuiTableFlags_SizingStretchSame",  Tooltip = "Columns default to _WidthStretch with same weights." }
}


local flags_8 = ImGui.TableFlags_ScrollY | ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg | ImGui.TableFlags_Resizable
local contents_type = CT_ShowWidth
local column_count = 3
local flags_9 = ImGui.TableFlags_ScrollY | ImGui.TableFlags_RowBg | ImGui.TableFlags_BordersOuter | ImGui.TableFlags_BordersV | ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable
-- Make the UI compact because there are so many fields
local function pushStyleCompact(ui)
    local style = ui:getStyle()
	local fx, fy = style:getFramePadding()
	local ix, iy = style:getItemSpacing()
    ui:pushStyleVar(ImGui.StyleVar_FramePadding, fx, fy * 0.6)
    ui:pushStyleVar(ImGui.StyleVar_ItemSpacing, ix, iy * 0.6)
end
--
local function popStyleCompact(ui)
    ui:popStyleVar(2)
end
--
local function helpMarker(ui, desc)
    ui:textDisabled("(?)")
    if (ui:isItemHovered()) then
        ui:beginTooltip()
        ui:pushTextWrapPos(ui:getFontSize() * 35)
        ui:text(desc)
        ui:popTextWrapPos()
        ui:endTooltip()
    end
end
--
local function editTableSizingFlags(ui, p_flags)
    local idx = 1
    for i = 1, #policies do
        if (policies[i].Value == (p_flags & ImGuiTableFlags_SizingMask_)) then
            break
		else
			idx += 1
		end
	end
	
    local preview_text = (idx < #policies) and (policies[idx].Name + (idx > 0 and string.len("ImGuiTableFlags") or 0)) or ""
	
    if (ui:beginCombo("Sizing Policy", preview_text)) then
        for n = 1, #policies do
            if (ui:selectable(policies[n].Name, idx == n)) then 
                p_flags = (p_flags & ~ImGuiTableFlags_SizingMask_) | policies[n].Value
			end
		end
        ui:endCombo()
    end
	
    ui:sameLine();
    ui:textDisabled("(?)")
    if (ui:isItemHovered()) then
        ui:beginTooltip()
        ui:pushTextWrapPos(ui:getFontSize() * 50)
		
		local isx = ui:getStyle():getIndentSpacing()
        for m = 1, #policies do
            ui:separator()
            ui:text(policies[m].Name)
            ui:separator()
            ui:setCursorPosX(ui:getCursorPosX() + isx * 0.5)
            ui:text(policies[m].Tooltip)
        end
        ui:popTextWrapPos()
        ui:endTooltip()
    end
	
	return p_flags
end

local function EditTableColumnsFlags(ui, p_flags) -- TODO
    p_flags = ui:checkboxFlags("_DefaultHide", p_flags, ImGuiTableColumnFlags_DefaultHide)
    p_flags = ui:checkboxFlags("_DefaultSort", p_flags, ImGuiTableColumnFlags_DefaultSort)
	
    --if (ui:checkboxFlags("_WidthStretch", p_flags, ImGuiTableColumnFlags_WidthStretch))
    --    *;
    --if (ui:checkboxFlags("_WidthFixed", p_flags, ImGuiTableColumnFlags_WidthFixed))
    --    *p_flags &= ~(ImGuiTableColumnFlags_WidthMask_ ^ ImGuiTableColumnFlags_WidthFixed);
	
    p_flags = ui:checkboxFlags("_NoResize", p_flags, ImGuiTableColumnFlags_NoResize)
    p_flags = ui:checkboxFlags("_NoReorder", p_flags, ImGuiTableColumnFlags_NoReorder)
    p_flags = ui:checkboxFlags("_NoHide", p_flags, ImGuiTableColumnFlags_NoHide)
    p_flags = ui:checkboxFlags("_NoClip", p_flags, ImGuiTableColumnFlags_NoClip)
    p_flags = ui:checkboxFlags("_NoSort", p_flags, ImGuiTableColumnFlags_NoSort)
    p_flags = ui:checkboxFlags("_NoSortAscending", p_flags, ImGuiTableColumnFlags_NoSortAscending)
    p_flags = ui:checkboxFlags("_NoSortDescending", p_flags, ImGuiTableColumnFlags_NoSortDescending)
    p_flags = ui:checkboxFlags("_NoHeaderWidth", p_flags, ImGuiTableColumnFlags_NoHeaderWidth)
    p_flags = ui:checkboxFlags("_PreferSortAscending", p_flags, ImGuiTableColumnFlags_PreferSortAscending)
    p_flags = ui:checkboxFlags("_PreferSortDescending", p_flags, ImGuiTableColumnFlags_PreferSortDescending)
    p_flags = ui:checkboxFlags("_IndentEnable", p_flags, ImGuiTableColumnFlags_IndentEnable); ImGui::SameLine(); HelpMarker("Default for column 0")
    p_flags = ui:checkboxFlags("_IndentDisable", p_flags, ImGuiTableColumnFlags_IndentDisable); ImGui::SameLine(); HelpMarker("Default for column >0")
end

local function showTableColumnsStatusFlags(ui, flags)
    flags = ImGui::CheckboxFlags("_IsEnabled", flags, ImGuiTableColumnFlags_IsEnabled)
    flags = ImGui::CheckboxFlags("_IsVisible", flags, ImGuiTableColumnFlags_IsVisible)
    flags = ImGui::CheckboxFlags("_IsSorted", flags, ImGuiTableColumnFlags_IsSorted)
    flags = ImGui::CheckboxFlags("_IsHovered", flags, ImGuiTableColumnFlags_IsHovered)
	return flags
end
--
function showDemoWindowTables(ui)
    if (not ui:collapsingHeader("Tables & Columns")) then
		return
	end
	
    -- Using those as a base value to create width/height that are factor of the size of our font
    local TEXT_BASE_WIDTH = ui:calcTextSize("A")
    local TEXT_BASE_HEIGHT = ui:getTextLineHeightWithSpacing()

    ui:pushID("Tables")

    local open_action = -1
    if (ui:button("Open all")) then open_action = 1 end
    ui:sameLine()
	
    if (ui:button("Close all")) then  open_action = 0 end
	ui:sameLine()

    -- Options
    disable_indent = ui:checkbox("Disable tree indentation", disable_indent)
    ui:sameLine()
    helpMarker(ui, "Disable the indenting of tree nodes so demo tables can use the full window width.")
    ui:separator()
    if (disable_indent) then ui:PushStyleVar(ImGui.StyleVar_indentSpacing, 0) end
	
	-- Demos
    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
	end
	
    if (ui:treeNode("Basic")) then
        -- Here we will showcase three different ways to output a table.
        -- They are very simple variations of a same thing!

        -- [Method 1] Using TableNextRow() to create a new row, and TableSetColumnIndex() to select the column.
        -- In many situations, this is the most flexible and easy to use pattern.
        helpMarker(ui, "Using TableNextRow() + calling TableSetColumnIndex() _before_ each cell, in a loop.")
        if (ui:beginTable("table1", 3)) then
            --for (int row = 0 row < 4 row++)
			for row = 0, 3 do
                ui:TableNextRow()
                for column = 0, 2 do
                    ui:tableSetColumnIndex(column)
                    ui:text(("Row %d Column %d"):format(row, column))
                end
            end
            ui:endTable()
        end

        -- [Method 2] Using TableNextColumn() called multiple times, instead of using a for loop + TableSetColumnIndex().
        -- This is generally more convenient when you have code manually submitting the contents of each columns.
        helpMarker(ui, "Using TableNextRow() + calling TableNextColumn() _before_ each cell, manually.")
        if (ui:beginTable("table2", 3)) then
            for row = 0, 3 do
                ui:tableNextRow()
                ui:tableNextColumn()
                ui:text(("Row %d"):format(row))
                ui:tableNextColumn()
                ui:text("Some contents")
                ui:tableNextColumn()
                ui:text("123.456")
            end
            ui:endTable()
        end

        -- [Method 3] We call TableNextColumn() _before_ each cell. We never call TableNextRow(),
        -- as TableNextColumn() will automatically wrap around and create new roes as needed.
        -- This is generally more convenient when your cells all contains the same type of data.
        helpMarker(
            "Only using TableNextColumn(), which tends to be convenient for tables where every cells contains the same type of contents.\n"
            "This is also more similar to the old NextColumn() function of the Columns API, and provided to facilitate the Columns->Tables API transition.")
        if (ui:beginTable("table3", 3)) then
            --for (int item = 0 item < 14 item++)
            for item = 0, 13 do
                ui:tableNextColumn()
                ui:text(("Item %d"):format(item))
            end
            ui:endTable()
        end
		
        ui:treePop()
    end

    if (open_action ~= -1) then 
        ui:setNextItemOpen(open_action ~= 0)
	end
	
    if (ui:treeNode("Borders, background")) then
        -- Expose a few Borders related flags_1 interactively
        pushStyleCompact(ui)
        flags_1 = ui:checkboxFlags("ImGui.TableFlags_RowBg", flags_1, ImGui.TableFlags_RowBg)
        flags_1 = ui:checkboxFlags("ImGui.TableFlags_Borders", flags_1, ImGui.TableFlags_Borders)
        ui:sameLine() helpMarker(ui, "ImGui.TableFlags_Borders\n = ImGui.TableFlags_BordersInnerV\n | ImGui.TableFlags_BordersOuterV\n | ImGui.TableFlags_BordersInnerV\n | ImGui.TableFlags_BordersOuterH")
        ui:indent()

        flags_1 = ui:checkboxFlags("ImGui.TableFlags_BordersH", flags_1, ImGui.TableFlags_BordersH)
        ui:indent()
        flags_1 = ui:checkboxFlags("ImGui.TableFlags_BordersOuterH", flags_1, ImGui.TableFlags_BordersOuterH)
        flags_1 = ui:checkboxFlags("ImGui.TableFlags_BordersInnerH", flags_1, ImGui.TableFlags_BordersInnerH)
        ui:unindent()

        flags_1 = ui:checkboxFlags("ImGui.TableFlags_BordersV", flags_1, ImGui.TableFlags_BordersV)
        ui:indent()
        flags_1 = ui:checkboxFlags("ImGui.TableFlags_BordersOuterV", flags_1, ImGui.TableFlags_BordersOuterV)
        flags_1 = ui:checkboxFlags("ImGui.TableFlags_BordersInnerV", flags_1, ImGui.TableFlags_BordersInnerV)
        ui:unindent()

        flags_1 = ui:checkboxFlags("ImGui.TableFlags_BordersOuter", flags_1, ImGui.TableFlags_BordersOuter)
        flags_1 = ui:checkboxFlags("ImGui.TableFlags_BordersInner", flags_1, ImGui.TableFlags_BordersInner)
        ui:unindent()

        ui:AlignTextToFramePadding() 
		ui:Text("Cell contents:")
        ui:sameLine() 
		contents_type = ui:RadioButton("Text", contents_type, CT_Text)
        ui:sameLine() 
		contents_type = ui:RadioButton("FillButton", contents_type, CT_FillButton)
		
        display_headers = ui:checkbox("Display headers", display_headers)
		
        flags_1 = ui:checkboxFlags("ImGui.TableFlags_NoBordersInBody", flags_1, ImGui.TableFlags_NoBordersInBody)
		ui:sameLine() 
		helpMarker(ui, "Disable vertical borders in columns Body (borders will always appears in Headers")
        popStyleCompact(ui)

        if (ui:beginTable("table1", 3, flags_1)) then
            -- Display headers so we can inspect their interaction with borders.
            -- (Headers are not the main purpose of this section of the demo, so we are not elaborating on them too much. See other sections for details)
            if (display_headers) then
                ui:TableSetupColumn("One")
                ui:TableSetupColumn("Two")
                ui:TableSetupColumn("Three")
                ui:tableHeadersRow()
            end

            for row = 0, 4 do
                ui:tableNextRow()
                for column = 0, 2 do
                    ui:tableSetColumnIndex(column)
                    local text = ("Hello %d,%d"):format(column, row)
                    if (contents_type == CT_Text) then
                        ui:text(text)
                    elseif (contents_type)
                        ui:button(text, -1, 0)
					end
                end
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1) then
        ui:setNextItemOpen(open_action ~= 0)
	end
	
    if (ui:treeNode("Resizable, stretch")) then
        -- By default, if we don't enable ScrollX the sizing policy for each columns is "Stretch"
        -- Each columns maintain a sizing weight, and they will occupy all available width.
        
        pushStyleCompact(ui)
        flags_2 = ui:checkboxFlags("ImGui.TableFlags_Resizable", flags_2, ImGui.TableFlags_Resizable)
        flags_2 = ui:checkboxFlags("ImGui.TableFlags_BordersV", flags_2, ImGui.TableFlags_BordersV)
        ui:sameLine() 
		helpMarker(ui, "Using the _Resizable flag automatically enables the _BordersInnerV flag as well, this is why the resize borders are still showing when unchecking this.")
        popStyleCompact(ui)

        if (ui:beginTable("table1", 3, flags_2)) then
            --for row = 0, 4 do
            for row = 0, 4 do
                ui:tableNextRow()
                for column = 0, 2 do
                    ui:tableSetColumnIndex(column)
                    ui:text(("Hello %d,%d"):format(column, row))
                end
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1) then
        ui:setNextItemOpen(open_action ~= 0)
	end
	
    if (ui:treeNode("Resizable, fixed")) then 
        -- Here we use ImGui.TableFlags_SizingFixedFit (even though _ScrollX is not set)
        -- So columns will adopt the "Fixed" policy and will maintain a fixed width regardless of the whole available width (unless table is small)
        -- If there is not enough available width to fit all columns, they will however be resized down.
        -- FIXME-TABLE: Providing a stretch-on-init would make sense especially for tables which don't have saved settings
        helpMarker([[
Using _Resizable + _SizingFixedFit flags.
Fixed-width columns generally makes more sense if you want to use horizontal scrolling.
Double-click a column border to auto-fit the column to its contents.]])
        pushStyleCompact(ui)
        
        flags_3 = ui:checkboxFlags("ImGui.TableFlags_NoHostExtendX", flags_3, ImGui.TableFlags_NoHostExtendX)
        popStyleCompact(ui)

        if (ui:beginTable("table1", 3, flags_3)) then
            for row = 0, 4 do
                ui:tableNextRow()
                for column = 0, 2 do
                    ui:tableSetColumnIndex(column)
                    ui:text(("Hello %d,%d"):format(column, row))
                end
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1) then
        ui:setNextItemOpen(open_action ~= 0)
	end
	
    if (ui:treeNode("Resizable, mixed")) then
        helpMarker([[
Using TableSetupColumn() to alter resizing policy on a per-column basis.
When combining Fixed and Stretch columns, generally you only want one, maybe two trailing columns to use _WidthStretch.]])
        if (ui:beginTable("table1", 3, flags_4)) then
            ui:tableSetupColumn("AAA", ImGui.TableColumnFlags_WidthFixed)
            ui:tableSetupColumn("BBB", ImGui.TableColumnFlags_WidthFixed)
            ui:tableSetupColumn("CCC", ImGui.TableColumnFlags_WidthStretch)
            ui:tableHeadersRow()
            for row = 0, 4 do
                ui:tableNextRow()
                for column = 0, 2 do
                    ui:tableSetColumnIndex(column)
					if (column == 2) then 
						ui:text(("Stretch %d,%d"):format(column, row))
					else
						ui:text(("Fixed %d,%d"):format(column, row))
					end
                end
            end
            ui:endTable()
        end
        if (ui:beginTable("table2", 6, flags_4)) then
            ui:tableSetupColumn("AAA", ImGui.TableColumnFlags_WidthFixed)
            ui:tableSetupColumn("BBB", ImGui.TableColumnFlags_WidthFixed)
            ui:tableSetupColumn("CCC", ImGui.TableColumnFlags_WidthFixed | ImGui.TableColumnFlags_DefaultHide)
            ui:tableSetupColumn("DDD", ImGui.TableColumnFlags_WidthStretch)
            ui:tableSetupColumn("EEE", ImGui.TableColumnFlags_WidthStretch)
            ui:tableSetupColumn("FFF", ImGui.TableColumnFlags_WidthStretch | ImGui.TableColumnFlags_DefaultHide)
            ui:tableHeadersRow()
            for row = 0, 4 do
                ui:tableNextRow()
                for column = 0, 5 do
                    ui:tableSetColumnIndex(column)
					if (column >= 3) then 
						ui:text(("Stretch %d,%d"):format(column, row))
					else
						ui:text(("Fixed %d,%d"):format(column, row))
					end
                end
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1) then
        ui:setNextItemOpen(open_action ~= 0)
	end
	
    if (ui:treeNode("Reorderable, hideable, with headers")) then
        helpMarker([[
Click and drag column headers to reorder columns.
Right-click on a header to open a context menu.]])
        
        pushStyleCompact(ui)
        flags_5 = ui:checkboxFlags("ImGui.TableFlags_Resizable", flags_5, ImGui.TableFlags_Resizable)
        flags_5 = ui:checkboxFlags("ImGui.TableFlags_Reorderable", flags_5, ImGui.TableFlags_Reorderable)
        flags_5 = ui:checkboxFlags("ImGui.TableFlags_Hideable", flags_5, ImGui.TableFlags_Hideable)
        flags_5 = ui:checkboxFlags("ImGui.TableFlags_NoBordersInBody", flags_5, ImGui.TableFlags_NoBordersInBody)
        flags_5 = ui:checkboxFlags("ImGui.TableFlags_NoBordersInBodyUntilResize", flags_5, ImGui.TableFlags_NoBordersInBodyUntilResize)
		ui:sameLine() 
		helpMarker(ui, "Disable vertical borders in columns Body until hovered for resize (borders will always appears in Headers)")
        popStyleCompact(ui)

        if (ui:beginTable("table1", 3, flags_5)) then
            -- Submit columns name with TableSetupColumn() and call TableHeadersRow() to create a row with a header in each column.
            -- (Later we will show how TableSetupColumn() has other uses, optional flags, sizing weight etc.)
            ui:tableSetupColumn("One")
            ui:tableSetupColumn("Two")
            ui:tableSetupColumn("Three")
            ui:tableHeadersRow()
            for row = 0, 5 do
                ui:tableNextRow()
                for column = 0, 2 do 
                    ui:tableSetColumnIndex(column)
                    ui:text(("Hello %d,%d"):format(column, row))
                end
            end
            ui:endTable()
        end

        -- Use outer_size.x == 0.0f instead of default to make the table as tight as possible (only valid when no scrolling and no stretch column)
        if (ui:beginTable("table2", 3, flags_5 | ImGui.TableFlags_SizingFixedFit, 0, 0)) then
            ui:tableSetupColumn("One")
            ui:tableSetupColumn("Two")
            ui:tableSetupColumn("Three")
            ui:tableHeadersRow()
            for row = 0, 5 do
                ui:tableNextRow()
                for column = 0, 2 do 
                    ui:tableSetColumnIndex(column)
                    ui:text(("Fixed %d,%d"):format(column, row))
                end
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1) then
        ui:setNextItemOpen(open_action ~= 0)
	end
	
    if (ui:treeNode("Padding")) then
        -- First example: showcase use of padding flags and effect of BorderOuterV/BorderInnerV on X padding.
        -- We don't expose BorderOuterH/BorderInnerH here because they have no effect on X padding.
        helpMarker([[
We often want outer padding activated when any using features which makes the edges of a column visible:
e.g.:
- BorderOuterV
- any form of row selection
Because of this, activating BorderOuterV sets the default to PadOuterX. Using PadOuterX or NoPadOuterX you can override the default.
Actual padding values are using style.CellPadding.
In this demo we don't show horizontal borders to emphasis how they don't affect default horizontal padding.]])

        pushStyleCompact(ui)
        flags_6_1 = ui:checkboxFlags("ImGui.TableFlags_PadOuterX", flags_6_1, ImGui.TableFlags_PadOuterX)
        ui:sameLine() helpMarker(ui, "Enable outer-most padding (default if ImGui.TableFlags_BordersOuterV is set)")
        flags_6_1 = ui:checkboxFlags("ImGui.TableFlags_NoPadOuterX", flags_6_1, ImGui.TableFlags_NoPadOuterX)
        ui:sameLine() helpMarker(ui, "Disable outer-most padding (default if ImGui.TableFlags_BordersOuterV is not set)")
        flags_6_1 = ui:checkboxFlags("ImGui.TableFlags_NoPadInnerX", flags_6_1, ImGui.TableFlags_NoPadInnerX)
        ui:sameLine() helpMarker(ui, "Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off)")
        flags_6_1 = ui:checkboxFlags("ImGui.TableFlags_BordersOuterV", flags_6_1, ImGui.TableFlags_BordersOuterV)
        flags_6_1 = ui:checkboxFlags("ImGui.TableFlags_BordersInnerV", flags_6_1, ImGui.TableFlags_BordersInnerV)
        static bool show_headers = false
        show_headers = ui:checkbox("show_headers", show_headers)
        popStyleCompact(ui)

        if (ui:beginTable("table_padding", 3, flags_6_1)) then
            if (show_headers) then
                ui:tableSetupColumn("One")
                ui:tableSetupColumn("Two")
                ui:tableSetupColumn("Three")
                ui:tableHeadersRow()
            end

            for row = 0, 4 do
                ui:tableNextRow()
                for column = 0, 2 do
                    ui:tableSetColumnIndex(column)
                    if (row == 0) then
						local x = ui:getContentRegionAvail()
                        ui:text(("Avail %.2f"):format(x))
                    else
                        ui:button(("Hello %d,%d"):format(column, row), -1, 0)
                    end
                end
            end
            ui:endTable()
        end

        -- Second example: set style.CellPadding to (0.0) or a custom value.
        -- FIXME-TABLE: Vertical border effectively not displayed the same way as horizontal one...
        helpMarker(ui, "Setting style.CellPadding to (0,0) or a custom value.")
        
        pushStyleCompact(ui)
        flags_6_2 = ui:checkboxFlags("ImGui.TableFlags_Borders", flags_6_2, ImGui.TableFlags_Borders)
        flags_6_2 = ui:checkboxFlags("ImGui.TableFlags_BordersH", flags_6_2, ImGui.TableFlags_BordersH)
        flags_6_2 = ui:checkboxFlags("ImGui.TableFlags_BordersV", flags_6_2, ImGui.TableFlags_BordersV)
        flags_6_2 = ui:checkboxFlags("ImGui.TableFlags_BordersInner", flags_6_2, ImGui.TableFlags_BordersInner)
        flags_6_2 = ui:checkboxFlags("ImGui.TableFlags_BordersOuter", flags_6_2, ImGui.TableFlags_BordersOuter)
        flags_6_2 = ui:checkboxFlags("ImGui.TableFlags_RowBg", flags_6_2, ImGui.TableFlags_RowBg)
        flags_6_2 = ui:checkboxFlags("ImGui.TableFlags_Resizable", flags_6_2, ImGui.TableFlags_Resizable)
        show_widget_frame_bg = ui:checkbox("show_widget_frame_bg", show_widget_frame_bg)
        cell_padding_x, cell_padding_y = ui:sliderFloat2("CellPadding", cell_padding_x, cell_padding_y, 0, 10)
        popStyleCompact(ui)

        ui:pushStyleVar(ImGui.StyleVar_CellPadding, cell_padding)
		--[[ TODO
        if (ui:beginTable("table_padding_2", 3, flags_6_2)) then
            static char text_bufs[3 * 5][16] -- Mini text storage for 3x5 cells
            static bool init = true
            if (!show_widget_frame_bg)
                ui:PushStyleColor(ImGuiCol_FrameBg, 0)
            for (int cell = 0 cell < 3 * 5 cell++)
            {
                ui:tableNextColumn()
                if (init)
                    strcpy(text_bufs[cell], "edit me")
                ui:SetNextItemWidth(-FLT_MIN)
                ui:pushID(cell)
                ui:InputText("##cell", text_bufs[cell], IM_ARRAYSIZE(text_bufs[cell]))
                ui:popID()
            end
            if (!show_widget_frame_bg)
                ui:PopStyleColor()
            init = false
            ui:endTable()
        end
		]]
        ui:popStyleVar()

        ui:treePop()
    end

    if (open_action ~= -1) then
        ui:setNextItemOpen(open_action ~= 0)
	end
    if (ui:treeNode("Sizing policies")) then
        pushStyleCompact(ui)
        flags_7_1 = ui:checkboxFlags("ImGui.TableFlags_Resizable", flags_7_1, ImGui.TableFlags_Resizable)
        flags_7_1 = ui:checkboxFlags("ImGui.TableFlags_NoHostExtendX", flags_7_1, ImGui.TableFlags_NoHostExtendX)
        popStyleCompact(ui)

        
        for table_n = 0, 3 do
            ui:pushID(table_n)
            ui:setNextItemWidth(TEXT_BASE_WIDTH * 30)
            sizing_policy_flags[table_n] = EditTableSizingFlags(sizing_policy_flags[table_n])

            -- To make it easier to understand the different sizing policy,
            -- For each policy: we display one table where the columns have equal contents width, and one where the columns have different contents width.
            if (ui:beginTable("table1", 3, sizing_policy_flags[table_n] | flags_7_1))
                for row = 0, 2 do
                    ui:tableNextRow()
                    ui:tableNextColumn() ui:text("Oh dear")
                    ui:tableNextColumn() ui:text("Oh dear")
                    ui:tableNextColumn() ui:text("Oh dear")
                end
                ui:endTable()
            end
            if (ui:beginTable("table2", 3, sizing_policy_flags[table_n] | flags_7_1))
                for row = 0, 2 do
                    ui:tableNextRow()
                    ui:tableNextColumn() ui:text("AAAA")
                    ui:tableNextColumn() ui:text("BBBBBBBB")
                    ui:tableNextColumn() ui:text("CCCCCCCCCCCC")
                end
                ui:endTable()
            end
            ui:popID()
        end

        ui:Spacing()
        ui:textUnformatted("Advanced")
        ui:sameLine()
        helpMarker(ui, "This section allows you to interact and see the effect of various sizing policies depending on whether Scroll is enabled and the contents of your columns.")
		
		pushStyleCompact(ui)
        ui:pushID("Advanced")
        ui:pushItemWidth(TEXT_BASE_WIDTH * 30)
        flags = editTableSizingFlags(flags)
        contents_type = ui:combo("Contents", contents_type, "Show width\0Short Text\0Long Text\0Button\0Fill Button\0InputText\0")
        if (contents_type == CT_FillButton) then
            ui:sameLine()
            helpMarker(ui, "Be mindful that using right-alignment (e.g. size.x = -FLT_MIN) creates a feedback loop where contents width can feed into auto-column width can feed into contents width.")
        end
		
        column_count = ui:dragInt("Columns", column_count, 0.1, 1, 64, "%d", ImGuiSliderFlags_AlwaysClamp)
        flags_8 = ui:checkboxFlags("ImGui.TableFlags_Resizable", flags_8, ImGui.TableFlags_Resizable)
        flags_8 = ui:checkboxFlags("ImGui.TableFlags_PreciseWidths", flags_8, ImGui.TableFlags_PreciseWidths)
        ui:sameLine() 
		helpMarker(ui, "Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.")
        flags_8 = ui:checkboxFlags("ImGui.TableFlags_ScrollX", flags_8, ImGui.TableFlags_ScrollX)
        flags_8 = ui:checkboxFlags("ImGui.TableFlags_ScrollY", flags_8, ImGui.TableFlags_ScrollY)
        flags_8 = ui:checkboxFlags("ImGui.TableFlags_NoClip", flags_8, ImGui.TableFlags_NoClip)
        ui:popItemWidth()
        ui:popID()
        popStyleCompact(ui)

        if (ui:beginTable("table2", column_count, flags, 0, TEXT_BASE_HEIGHT * 7))
            for cell = 0, 9 * column_count do
                ui:tableNextColumn()
                local column = ui:tableGetColumnIndex()
                local row = ui:tableGetRowIndex()

                ui:pushID(cell)
				--[[ TODO
                char label[32]
                static char text_buf[32] = ""
                sprintf(label, "Hello %d,%d", column, row)
                switch (contents_type)
                {
                case CT_ShortText:  ui:textUnformatted(label) break
                case CT_LongText:   ui:text("Some %s text %d,%d\nOver two lines..", column == 0 ? "long" : "longeeer", column, row) break
                case CT_ShowWidth:  ui:text("W: %.1f", ui:GetContentRegionAvail().x) break
                case CT_Button:     ui:button(label) break
                case CT_FillButton: ui:button(label, ImVec2(-FLT_MIN, 0.0f)) break
                case CT_InputText:  ui:SetNextItemWidth(-FLT_MIN) ui:InputText("##", text_buf, IM_ARRAYSIZE(text_buf)) break
                }
				]]
                ui:popID()
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1) then
        ui:setNextItemOpen(open_action ~= 0)
	end
	
    if (ui:treeNode("Vertical scrolling, with clipping")) then
        helpMarker(ui, "Here we activate ScrollY, which will create a child window container to allow hosting scrollable contents.\n\nWe also demonstrate using ImGuiListClipper to virtualize the submission of many items.")
        
        pushStyleCompact(ui)
        flags_9 = ui:checkboxFlags("ImGui.TableFlags_ScrollY", flags_9, ImGui.TableFlags_ScrollY)
        popStyleCompact(ui)

        -- When using ScrollX or ScrollY we need to specify a size for our table container!
        -- Otherwise by default the table will fit all available space, like a BeginChild() call.
        local outer_size_x = 0
		local outer_size_y = TEXT_BASE_HEIGHT * 8
		
        if (ui:beginTable("table_scrolly", 3, flags_9, outer_size_x, outer_size_y)) then
            ui:tableSetupScrollFreeze(0, 1) -- Make top row always visible
            ui:tableSetupColumn("One", ImGui.TableColumnFlags_None)
            ui:tableSetupColumn("Two", ImGui.TableColumnFlags_None)
            ui:tableSetupColumn("Three", ImGui.TableColumnFlags_None)
            ui:tableHeadersRow()

            -- Demonstrate using clipper for large vertical lists
            local clipper = ImGuiListClipper.new()
            clipper:beginClip(1000)
            while (clipper:step()) do
                for row = clipper:getDisplayStart(), clipper:getDisplayEnd() do
                    ui:tableNextRow()
                    for column = 0, 2 do
                        ui:tableSetColumnIndex(column)
                        ui:text(("Hello %d,%d"):format(column, row))
                    end
                end
            end
            ui:endTable()
        end
        ui:treePop()
    end
	--[[
    if (open_action ~= -1) then 
        ui:setNextItemOpen(open_action ~= 0)
	end
	
    if (ui:treeNode("Horizontal scrolling"))
    {
        helpMarker(
            "When ScrollX is enabled, the default sizing policy becomes ImGui.TableFlags_SizingFixedFit, "
            "as automatically stretching columns doesn't make much sense with horizontal scrolling.\n\n"
            "Also note that as of the current version, you will almost always want to enable ScrollY along with ScrollX,"
            "because the container window won't automatically extend vertically to fix contents (this may be improved in future versions).")
        static ImGui.TableFlags flags = ImGui.TableFlags_ScrollX | ImGui.TableFlags_ScrollY | ImGui.TableFlags_RowBg | ImGui.TableFlags_BordersOuter | ImGui.TableFlags_BordersV | ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable
        static int freeze_cols = 1
        static int freeze_rows = 1

        pushStyleCompact(ui)
        ui:checkboxFlags("ImGui.TableFlags_Resizable", &flags, ImGui.TableFlags_Resizable)
        ui:checkboxFlags("ImGui.TableFlags_ScrollX", &flags, ImGui.TableFlags_ScrollX)
        ui:checkboxFlags("ImGui.TableFlags_ScrollY", &flags, ImGui.TableFlags_ScrollY)
        ui:SetNextItemWidth(ui:GetFrameHeight())
        ui:DragInt("freeze_cols", &freeze_cols, 0.2f, 0, 9, NULL, ImGuiSliderFlags_NoInput)
        ui:SetNextItemWidth(ui:GetFrameHeight())
        ui:DragInt("freeze_rows", &freeze_rows, 0.2f, 0, 9, NULL, ImGuiSliderFlags_NoInput)
        popStyleCompact(ui)

        -- When using ScrollX or ScrollY we need to specify a size for our table container!
        -- Otherwise by default the table will fit all available space, like a BeginChild() call.
        ImVec2 outer_size = ImVec2(0.0f, TEXT_BASE_HEIGHT * 8)
        if (ui:beginTable("table_scrollx", 7, flags, outer_size))
        {
            ui:tableSetupScrollFreeze(freeze_cols, freeze_rows)
            ui:tableSetupColumn("Line #", ImGui.TableColumnFlags_NoHide) -- Make the first column not hideable to match our use of TableSetupScrollFreeze()
            ui:tableSetupColumn("One")
            ui:tableSetupColumn("Two")
            ui:tableSetupColumn("Three")
            ui:tableSetupColumn("Four")
            ui:tableSetupColumn("Five")
            ui:tableSetupColumn("Six")
            ui:tableHeadersRow()
            for (int row = 0 row < 20 row++)
            {
                ui:tableNextRow()
                for (int column = 0 column < 7 column++)
                {
                    -- Both TableNextColumn() and TableSetColumnIndex() return true when a column is visible or performing width measurement.
                    -- Because here we know that:
                    -- - A) all our columns are contributing the same to row height
                    -- - B) column 0 is always visible,
                    -- We only always submit this one column and can skip others.
                    -- More advanced per-column clipping behaviors may benefit from polling the status flags via TableGetColumnFlags().
                    if (!ui:tableSetColumnIndex(column) && column > 0)
                        continue
                    if (column == 0)
                        ui:text("Line %d", row)
                    else
                        ui:text("Hello world %d,%d", column, row)
                end
            end
            ui:endTable()
        end

        ui:Spacing()
        ui:textUnformatted("Stretch + ScrollX")
        ui:sameLine()
        helpMarker(
            "Showcase using Stretch columns + ScrollX together: "
            "this is rather unusual and only makes sense when specifying an 'inner_width' for the table!\n"
            "Without an explicit value, inner_width is == outer_size.x and therefore using Stretch columns + ScrollX together doesn't make sense.")
        static ImGui.TableFlags flags2 = ImGui.TableFlags_SizingStretchSame | ImGui.TableFlags_ScrollX | ImGui.TableFlags_ScrollY | ImGui.TableFlags_BordersOuter | ImGui.TableFlags_RowBg | ImGui.TableFlags_ContextMenuInBody
        static float inner_width = 1000.0f
        pushStyleCompact(ui)
        ui:pushID("flags3")
        ui:pushItemWidth(TEXT_BASE_WIDTH * 30)
        ui:checkboxFlags("ImGui.TableFlags_ScrollX", &flags2, ImGui.TableFlags_ScrollX)
        ui:DragFloat("inner_width", &inner_width, 1.0f, 0.0f, FLT_MAX, "%.1f")
        ui:popItemWidth()
        ui:popID()
        popStyleCompact(ui)
        if (ui:beginTable("table2", 7, flags2, outer_size, inner_width))
        {
            for (int cell = 0 cell < 20 * 7 cell++)
            {
                ui:tableNextColumn()
                ui:text("Hello world %d,%d", ui:tableGetColumnIndex(), ui:tableGetRowIndex())
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Columns flags"))
    {
        -- Create a first table just to show all the options/flags we want to make visible in our example!
        const int column_count = 3
        const char* column_names[column_count] = { "One", "Two", "Three" end
        static ImGui.TableColumnFlags column_flags[column_count] = { ImGui.TableColumnFlags_DefaultSort, ImGui.TableColumnFlags_None, ImGui.TableColumnFlags_DefaultHide end
        static ImGui.TableColumnFlags column_flags_out[column_count] = { 0, 0, 0 end -- Output from TableGetColumnFlags()

        if (ui:beginTable("table_columns_flags_checkboxes", column_count, ImGui.TableFlags_None))
        {
            pushStyleCompact(ui)
            for (int column = 0 column < column_count column++)
            {
                ui:tableNextColumn()
                ui:pushID(column)
                ui:AlignTextToFramePadding() -- FIXME-TABLE: Workaround for wrong text baseline propagation
                ui:text("'%s'", column_names[column])
                ui:Spacing()
                ui:text("Input flags:")
                EditTableColumnsFlags(&column_flags[column])
                ui:Spacing()
                ui:text("Output flags:")
                ShowTableColumnsStatusFlags(column_flags_out[column])
                ui:popID()
            end
            popStyleCompact(ui)
            ui:endTable()
        end

        -- Create the real table we care about for the example!
        -- We use a scrolling table to be able to showcase the difference between the _IsEnabled and _IsVisible flags above, otherwise in
        -- a non-scrolling table columns are always visible (unless using ImGui.TableFlags_NoKeepColumnsVisible + resizing the parent window down)
        const ImGui.TableFlags flags
            = ImGui.TableFlags_SizingFixedFit | ImGui.TableFlags_ScrollX | ImGui.TableFlags_ScrollY
            | ImGui.TableFlags_RowBg | ImGui.TableFlags_BordersOuter | ImGui.TableFlags_BordersV
            | ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable | ImGui.TableFlags_Sortable
        ImVec2 outer_size = ImVec2(0.0f, TEXT_BASE_HEIGHT * 9)
        if (ui:beginTable("table_columns_flags", column_count, flags, outer_size))
        {
            for (int column = 0 column < column_count column++)
                ui:tableSetupColumn(column_names[column], column_flags[column])
            ui:tableHeadersRow()
            for (int column = 0 column < column_count column++)
                column_flags_out[column] = ui:tableGetColumnFlags(column)
            float indent_step = (float)((int)TEXT_BASE_WIDTH / 2)
            for (int row = 0 row < 8 row++)
            {
                ui:indent(indent_step) -- Add some indentation to demonstrate usage of per-column indentEnable/indentDisable flags.
                ui:tableNextRow()
                for (int column = 0 column < column_count column++)
                {
                    ui:tableSetColumnIndex(column)
                    ui:text("%s %s", (column == 0) ? "indented" : "Hello", ui:tableGetColumnName(column))
                end
            end
            ui:unindent(indent_step * 8.0f)

            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Columns widths"))
    {
        helpMarker(ui, "Using TableSetupColumn() to setup default width.")

        static ImGui.TableFlags flags1 = ImGui.TableFlags_Borders | ImGui.TableFlags_NoBordersInBodyUntilResize
        pushStyleCompact(ui)
        ui:checkboxFlags("ImGui.TableFlags_Resizable", &flags1, ImGui.TableFlags_Resizable)
        ui:checkboxFlags("ImGui.TableFlags_NoBordersInBodyUntilResize", &flags1, ImGui.TableFlags_NoBordersInBodyUntilResize)
        popStyleCompact(ui)
        if (ui:beginTable("table1", 3, flags1))
        {
            -- We could also set ImGui.TableFlags_SizingFixedFit on the table and all columns will default to ImGui.TableColumnFlags_WidthFixed.
            ui:tableSetupColumn("one", ImGui.TableColumnFlags_WidthFixed, 100.0f) -- Default to 100.0f
            ui:tableSetupColumn("two", ImGui.TableColumnFlags_WidthFixed, 200.0f) -- Default to 200.0f
            ui:tableSetupColumn("three", ImGui.TableColumnFlags_WidthFixed)       -- Default to auto
            ui:tableHeadersRow()
            for (int row = 0 row < 4 row++)
            {
                ui:tableNextRow()
                for column = 0, 2 do
                {
                    ui:tableSetColumnIndex(column)
                    if (row == 0)
                        ui:text("(w: %5.1f)", ui:GetContentRegionAvail().x)
                    else
                        ui:text(("Hello %d,%d"):format(column, row))
                end
            end
            ui:endTable()
        end

        helpMarker(ui, "Using TableSetupColumn() to setup explicit width.\n\nUnless _NoKeepColumnsVisible is set, fixed columns with set width may still be shrunk down if there's not enough space in the host.")

        static ImGui.TableFlags flags2 = ImGui.TableFlags_None
        pushStyleCompact(ui)
        ui:checkboxFlags("ImGui.TableFlags_NoKeepColumnsVisible", &flags2, ImGui.TableFlags_NoKeepColumnsVisible)
        ui:checkboxFlags("ImGui.TableFlags_BordersInnerV", &flags2, ImGui.TableFlags_BordersInnerV)
        ui:checkboxFlags("ImGui.TableFlags_BordersOuterV", &flags2, ImGui.TableFlags_BordersOuterV)
        popStyleCompact(ui)
        if (ui:beginTable("table2", 4, flags2))
        {
            -- We could also set ImGui.TableFlags_SizingFixedFit on the table and all columns will default to ImGui.TableColumnFlags_WidthFixed.
            ui:tableSetupColumn("", ImGui.TableColumnFlags_WidthFixed, 100.0f)
            ui:tableSetupColumn("", ImGui.TableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 15.0f)
            ui:tableSetupColumn("", ImGui.TableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 30.0f)
            ui:tableSetupColumn("", ImGui.TableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 15.0f)
            for row = 0, 4 do
            {
                ui:tableNextRow()
                for (int column = 0 column < 4 column++)
                {
                    ui:tableSetColumnIndex(column)
                    if (row == 0)
                        ui:text("(w: %5.1f)", ui:GetContentRegionAvail().x)
                    else
                        ui:text(("Hello %d,%d"):format(column, row))
                end
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Nested tables"))
    {
        helpMarker(ui, "This demonstrate embedding a table into another table cell.")

        if (ui:beginTable("table_nested1", 2, ImGui.TableFlags_Borders | ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable))
        {
            ui:tableSetupColumn("A0")
            ui:tableSetupColumn("A1")
            ui:tableHeadersRow()

            ui:tableNextColumn()
            ui:text("A0 Cell 0")
            {
                float rows_height = TEXT_BASE_HEIGHT * 2
                if (ui:beginTable("table_nested2", 2, ImGui.TableFlags_Borders | ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable))
                {
                    ui:tableSetupColumn("B0")
                    ui:tableSetupColumn("B1")
                    ui:tableHeadersRow()

                    ui:tableNextRow(ImGui.TableRowFlags_None, rows_height)
                    ui:tableNextColumn()
                    ui:text("B0 Cell 0")
                    ui:tableNextColumn()
                    ui:text("B0 Cell 1")
                    ui:tableNextRow(ImGui.TableRowFlags_None, rows_height)
                    ui:tableNextColumn()
                    ui:text("B1 Cell 0")
                    ui:tableNextColumn()
                    ui:text("B1 Cell 1")

                    ui:endTable()
                end
            end
            ui:tableNextColumn() ui:text("A0 Cell 1")
            ui:tableNextColumn() ui:text("A1 Cell 0")
            ui:tableNextColumn() ui:text("A1 Cell 1")
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Row height"))
    {
        helpMarker(ui, "You can pass a 'min_row_height' to TableNextRow().\n\nRows are padded with 'style.CellPadding.y' on top and bottom, so effectively the minimum row height will always be >= 'style.CellPadding.y * 2.0f'.\n\nWe cannot honor a _maximum_ row height as that would requires a unique clipping rectangle per row.")
        if (ui:beginTable("table_row_height", 1, ImGui.TableFlags_BordersOuter | ImGui.TableFlags_BordersInnerV))
        {
            for (int row = 0 row < 10 row++)
            {
                float min_row_height = (float)(int)(TEXT_BASE_HEIGHT * 0.30f * row)
                ui:tableNextRow(ImGui.TableRowFlags_None, min_row_height)
                ui:tableNextColumn()
                ui:text("min_row_height = %.2f", min_row_height)
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Outer size"))
    {
        -- Showcasing use of ImGui.TableFlags_NoHostExtendX and ImGui.TableFlags_NoHostExtendY
        -- Important to that note how the two flags have slightly different behaviors!
        ui:text("Using NoHostExtendX and NoHostExtendY:")
        pushStyleCompact(ui)
        static ImGui.TableFlags flags = ImGui.TableFlags_Borders | ImGui.TableFlags_Resizable | ImGui.TableFlags_ContextMenuInBody | ImGui.TableFlags_RowBg | ImGui.TableFlags_SizingFixedFit | ImGui.TableFlags_NoHostExtendX
        ui:checkboxFlags("ImGui.TableFlags_NoHostExtendX", &flags, ImGui.TableFlags_NoHostExtendX)
        ui:sameLine() helpMarker(ui, "Make outer width auto-fit to columns, overriding outer_size.x value.\n\nOnly available when ScrollX/ScrollY are disabled and Stretch columns are not used.")
        ui:checkboxFlags("ImGui.TableFlags_NoHostExtendY", &flags, ImGui.TableFlags_NoHostExtendY)
        ui:sameLine() helpMarker(ui, "Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).\n\nOnly available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.")
        popStyleCompact(ui)

        ImVec2 outer_size = ImVec2(0.0f, TEXT_BASE_HEIGHT * 5.5f)
        if (ui:beginTable("table1", 3, flags, outer_size))
        {
            for (int row = 0 row < 10 row++)
            {
                ui:tableNextRow()
                for column = 0, 2 do
                {
                    ui:tableNextColumn()
                    ui:text("Cell %d,%d", column, row)
                end
            end
            ui:endTable()
        end
        ui:sameLine()
        ui:text("Hello!")

        ui:Spacing()

        ui:text("Using explicit size:")
        if (ui:beginTable("table2", 3, ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg, ImVec2(TEXT_BASE_WIDTH * 30, 0.0f)))
        {
            for row = 0, 4 do
            {
                ui:tableNextRow()
                for column = 0, 2 do
                {
                    ui:tableNextColumn()
                    ui:text("Cell %d,%d", column, row)
                end
            end
            ui:endTable()
        end
        ui:sameLine()
        if (ui:beginTable("table3", 3, ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg, ImVec2(TEXT_BASE_WIDTH * 30, 0.0f)))
        {
            for (int row = 0 row < 3 row++)
            {
                ui:tableNextRow(0, TEXT_BASE_HEIGHT * 1.5f)
                for column = 0, 2 do
                {
                    ui:tableNextColumn()
                    ui:text("Cell %d,%d", column, row)
                end
            end
            ui:endTable()
        end

        ui:treePop()
    end

    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Background color"))
    {
        static ImGui.TableFlags flags = ImGui.TableFlags_RowBg
        static int row_bg_type = 1
        static int row_bg_target = 1
        static int cell_bg_type = 1

        pushStyleCompact(ui)
        ui:checkboxFlags("ImGui.TableFlags_Borders", &flags, ImGui.TableFlags_Borders)
        ui:checkboxFlags("ImGui.TableFlags_RowBg", &flags, ImGui.TableFlags_RowBg)
        ui:sameLine() helpMarker(ui, "ImGui.TableFlags_RowBg automatically sets RowBg0 to alternative colors pulled from the Style.")
        ui:Combo("row bg type", (int*)&row_bg_type, "None\0Red\0Gradient\0")
        ui:Combo("row bg target", (int*)&row_bg_target, "RowBg0\0RowBg1\0") ui:sameLine() helpMarker(ui, "Target RowBg0 to override the alternating odd/even colors,\nTarget RowBg1 to blend with them.")
        ui:Combo("cell bg type", (int*)&cell_bg_type, "None\0Blue\0") ui:sameLine() helpMarker(ui, "We are colorizing cells to B1->C2 here.")
        IM_ASSERT(row_bg_type >= 0 && row_bg_type <= 2)
        IM_ASSERT(row_bg_target >= 0 && row_bg_target <= 1)
        IM_ASSERT(cell_bg_type >= 0 && cell_bg_type <= 1)
        popStyleCompact(ui)

        if (ui:beginTable("table1", 5, flags))
        {
            for (int row = 0 row < 6 row++)
            {
                ui:tableNextRow()

                -- Demonstrate setting a row background color with 'ui:tableSetBgColor(ImGui.TableBgTarget_RowBgX, ...)'
                -- We use a transparent color so we can see the one behind in case our target is RowBg1 and RowBg0 was already targeted by the ImGui.TableFlags_RowBg flag.
                if (row_bg_type ~= 0)
                {
                    ImU32 row_bg_color = ui:GetColorU32(row_bg_type == 1 ? ImVec4(0.7f, 0.3f, 0.3f, 0.65f) : ImVec4(0.2f + row * 0.1f, 0.2f, 0.2f, 0.65f)) -- Flat or Gradient?
                    ui:tableSetBgColor(ImGui.TableBgTarget_RowBg0 + row_bg_target, row_bg_color)
                end

                -- Fill cells
                for (int column = 0 column < 5 column++)
                {
                    ui:tableSetColumnIndex(column)
                    ui:text("%c%c", 'A' + row, '0' + column)

                    -- Change background of Cells B1->C2
                    -- Demonstrate setting a cell background color with 'ui:tableSetBgColor(ImGui.TableBgTarget_CellBg, ...)'
                    -- (the CellBg color will be blended over the RowBg and ColumnBg colors)
                    -- We can also pass a column number as a third parameter to TableSetBgColor() and do this outside the column loop.
                    if (row >= 1 && row <= 2 && column >= 1 && column <= 2 && cell_bg_type == 1)
                    {
                        ImU32 cell_bg_color = ui:GetColorU32(ImVec4(0.3f, 0.3f, 0.7f, 0.65f))
                        ui:tableSetBgColor(ImGui.TableBgTarget_CellBg, cell_bg_color)
                    end
                end
            end
            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Tree view"))
    {
        static ImGui.TableFlags flags = ImGui.TableFlags_BordersV | ImGui.TableFlags_BordersOuterH | ImGui.TableFlags_Resizable | ImGui.TableFlags_RowBg | ImGui.TableFlags_NoBordersInBody

        if (ui:beginTable("3ways", 3, flags))
        {
            -- The first column will use the default _WidthStretch when ScrollX is Off and _WidthFixed when ScrollX is On
            ui:tableSetupColumn("Name", ImGui.TableColumnFlags_NoHide)
            ui:tableSetupColumn("Size", ImGui.TableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 12.0f)
            ui:tableSetupColumn("Type", ImGui.TableColumnFlags_WidthFixed, TEXT_BASE_WIDTH * 18.0f)
            ui:tableHeadersRow()

            -- Simple storage to output a dummy file-system.
            struct MytreeNode
            {
                const char*     Name
                const char*     Type
                int             Size
                int             ChildIdx
                int             ChildCount
                static void DisplayNode(const MytreeNode* node, const MytreeNode* all_nodes)
                {
                    ui:tableNextRow()
                    ui:tableNextColumn()
                    const bool is_folder = (node->ChildCount > 0)
                    if (is_folder)
                    {
                        bool open = ui:treeNodeEx(node->Name, ImGuitreeNodeFlags_SpanFullWidth)
                        ui:tableNextColumn()
                        ui:textDisabled("--")
                        ui:tableNextColumn()
                        ui:textUnformatted(node->Type)
                        if (open)
                        {
                            for (int child_n = 0 child_n < node->ChildCount child_n++)
                                DisplayNode(&all_nodes[node->ChildIdx + child_n], all_nodes)
                            ui:treePop()
                        end
                    end
                    else
                    {
                        ui:treeNodeEx(node->Name, ImGuitreeNodeFlags_Leaf | ImGuitreeNodeFlags_Bullet | ImGuitreeNodeFlags_NoTreePushOnOpen | ImGuitreeNodeFlags_SpanFullWidth)
                        ui:tableNextColumn()
                        ui:text("%d", node->Size)
                        ui:tableNextColumn()
                        ui:textUnformatted(node->Type)
                    end
                end
            end
            static const MytreeNode nodes[] =
            {
                { "Root",                         "Folder",       -1,       1, 3    end, -- 0
                { "Music",                        "Folder",       -1,       4, 2    end, -- 1
                { "Textures",                     "Folder",       -1,       6, 3    end, -- 2
                { "desktop.ini",                  "System file",  1024,    -1,-1    end, -- 3
                { "File1_a.wav",                  "Audio file",   123000,  -1,-1    end, -- 4
                { "File1_b.wav",                  "Audio file",   456000,  -1,-1    end, -- 5
                { "Image001.png",                 "Image file",   203128,  -1,-1    end, -- 6
                { "Copy of Image001.png",         "Image file",   203256,  -1,-1    end, -- 7
                { "Copy of Image001 (Final2).png","Image file",   203512,  -1,-1    end, -- 8
            end

            MytreeNode::DisplayNode(&nodes[0], nodes)

            ui:endTable()
        end
        ui:treePop()
    end

    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Item width"))
    {
        helpMarker(
            "Showcase using PushItemWidth() and how it is preserved on a per-column basis.\n\n"
            "Note that on auto-resizing non-resizable fixed columns, querying the content width for e.g. right-alignment doesn't make sense.")
        if (ui:beginTable("table_item_width", 3, ImGui.TableFlags_Borders))
        {
            ui:tableSetupColumn("small")
            ui:tableSetupColumn("half")
            ui:tableSetupColumn("right-align")
            ui:tableHeadersRow()

            for (int row = 0 row < 3 row++)
            {
                ui:tableNextRow()
                if (row == 0)
                {
                    -- Setup ItemWidth once (instead of setting up every time, which is also possible but less efficient)
                    ui:tableSetColumnIndex(0)
                    ui:pushItemWidth(TEXT_BASE_WIDTH * 3.0f) -- Small
                    ui:tableSetColumnIndex(1)
                    ui:pushItemWidth(-ui:GetContentRegionAvail().x * 0.5f)
                    ui:tableSetColumnIndex(2)
                    ui:pushItemWidth(-FLT_MIN) -- Right-aligned
                end

                -- Draw our contents
                static float dummy_f = 0.0f
                ui:pushID(row)
                ui:tableSetColumnIndex(0)
                ui:SliderFloat("float0", &dummy_f, 0.0f, 1.0f)
                ui:tableSetColumnIndex(1)
                ui:SliderFloat("float1", &dummy_f, 0.0f, 1.0f)
                ui:tableSetColumnIndex(2)
                ui:SliderFloat("float2", &dummy_f, 0.0f, 1.0f)
                ui:popID()
            end
            ui:endTable()
        end
        ui:treePop()
    end

    -- Demonstrate using TableHeader() calls instead of TableHeadersRow()
    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Custom headers"))
    {
        const int COLUMNS_COUNT = 3
        if (ui:beginTable("table_custom_headers", COLUMNS_COUNT, ImGui.TableFlags_Borders | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable))
        {
            ui:tableSetupColumn("Apricot")
            ui:tableSetupColumn("Banana")
            ui:tableSetupColumn("Cherry")

            -- Dummy entire-column selection storage
            -- FIXME: It would be nice to actually demonstrate full-featured selection using those checkbox.
            static bool column_selected[3] = {end

            -- Instead of calling TableHeadersRow() we'll submit custom headers ourselves
            ui:tableNextRow(ImGui.TableRowFlags_Headers)
            for (int column = 0 column < COLUMNS_COUNT column++)
            {
                ui:tableSetColumnIndex(column)
                const char* column_name = ui:tableGetColumnName(column) -- Retrieve name passed to TableSetupColumn()
                ui:pushID(column)
                ui:pushStyleVar(ImGui.StyleVar_FramePadding, ImVec2(0, 0))
                ui:checkbox("##checkall", &column_selected[column])
                ui:popStyleVar()
                ui:sameLine(0.0f, ui:GetStyle().ItemInnerSpacing.x)
                ui:tableHeader(column_name)
                ui:popID()
            end

            for row = 0, 4 do
            {
                ui:tableNextRow()
                for column = 0, 2 do
                {
                    char buf[32]
                    sprintf(buf, "Cell %d,%d", column, row)
                    ui:tableSetColumnIndex(column)
                    ui:Selectable(buf, column_selected[column])
                end
            end
            ui:endTable()
        end
        ui:treePop()
    end

    -- Demonstrate creating custom context menus inside columns, while playing it nice with context menus provided by TableHeadersRow()/TableHeader()
    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Context menus"))
    {
        helpMarker(ui, "By default, right-clicking over a TableHeadersRow()/TableHeader() line will open the default context-menu.\nUsing ImGui.TableFlags_ContextMenuInBody we also allow right-clicking over columns body.")
        static ImGui.TableFlags flags1 = ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable | ImGui.TableFlags_Borders | ImGui.TableFlags_ContextMenuInBody

        pushStyleCompact(ui)
        ui:checkboxFlags("ImGui.TableFlags_ContextMenuInBody", &flags1, ImGui.TableFlags_ContextMenuInBody)
        popStyleCompact(ui)

        -- Context Menus: first example
        -- [1.1] Right-click on the TableHeadersRow() line to open the default table context menu.
        -- [1.2] Right-click in columns also open the default table context menu (if ImGui.TableFlags_ContextMenuInBody is set)
        const int COLUMNS_COUNT = 3
        if (ui:beginTable("table_context_menu", COLUMNS_COUNT, flags1))
        {
            ui:tableSetupColumn("One")
            ui:tableSetupColumn("Two")
            ui:tableSetupColumn("Three")

            -- [1.1] Right-click on the TableHeadersRow() line to open the default table context menu.
            ui:tableHeadersRow()

            -- Submit dummy contents
            for (int row = 0 row < 4 row++)
            {
                ui:tableNextRow()
                for (int column = 0 column < COLUMNS_COUNT column++)
                {
                    ui:tableSetColumnIndex(column)
                    ui:text("Cell %d,%d", column, row)
                end
            end
            ui:endTable()
        end

        -- Context Menus: second example
        -- [2.1] Right-click on the TableHeadersRow() line to open the default table context menu.
        -- [2.2] Right-click on the ".." to open a custom popup
        -- [2.3] Right-click in columns to open another custom popup
        helpMarker(ui, "Demonstrate mixing table context menu (over header), item context button (over button) and custom per-colum context menu (over column body).")
        ImGui.TableFlags flags2 = ImGui.TableFlags_Resizable | ImGui.TableFlags_SizingFixedFit | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable | ImGui.TableFlags_Borders
        if (ui:beginTable("table_context_menu_2", COLUMNS_COUNT, flags2))
        {
            ui:tableSetupColumn("One")
            ui:tableSetupColumn("Two")
            ui:tableSetupColumn("Three")

            -- [2.1] Right-click on the TableHeadersRow() line to open the default table context menu.
            ui:tableHeadersRow()
            for (int row = 0 row < 4 row++)
            {
                ui:tableNextRow()
                for (int column = 0 column < COLUMNS_COUNT column++)
                {
                    -- Submit dummy contents
                    ui:tableSetColumnIndex(column)
                    ui:text("Cell %d,%d", column, row)
                    ui:sameLine()

                    -- [2.2] Right-click on the ".." to open a custom popup
                    ui:pushID(row * COLUMNS_COUNT + column)
                    ui:SmallButton("..")
                    if (ui:BeginPopupContextItem())
                    {
                        ui:text("This is the popup for Button(\"..\") in Cell %d,%d", column, row)
                        if (ui:button("Close"))
                            ui:CloseCurrentPopup()
                        ui:EndPopup()
                    end
                    ui:popID()
                end
            end

            -- [2.3] Right-click anywhere in columns to open another custom popup
            -- (instead of testing for !IsAnyItemHovered() we could also call OpenPopup() with ImGuiPopupFlags_NoOpenOverExistingPopup
            -- to manage popup priority as the popups triggers, here "are we hovering a column" are overlapping)
            int hovered_column = -1
            for (int column = 0 column < COLUMNS_COUNT + 1 column++)
            {
                ui:pushID(column)
                if (ui:tableGetColumnFlags(column) & ImGui.TableColumnFlags_IsHovered)
                    hovered_column = column
                if (hovered_column == column && !ui:IsAnyItemHovered() && ui:IsMouseReleased(1))
                    ui:OpenPopup("MyPopup")
                if (ui:BeginPopup("MyPopup"))
                {
                    if (column == COLUMNS_COUNT)
                        ui:text("This is a custom popup for unused space after the last column.")
                    else
                        ui:text("This is a custom popup for Column %d", column)
                    if (ui:button("Close"))
                        ui:CloseCurrentPopup()
                    ui:EndPopup()
                end
                ui:popID()
            end

            ui:endTable()
            ui:text("Hovered column: %d", hovered_column)
        end
        ui:treePop()
    end

    -- Demonstrate creating multiple tables with the same ID
    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Synced instances"))
    {
        helpMarker(ui, "Multiple tables with the same identifier will share their settings, width, visibility, order etc.")
        for (int n = 0 n < 3 n++)
        {
            char buf[32]
            sprintf(buf, "Synced Table %d", n)
            bool open = ui:CollapsingHeader(buf, ImGuitreeNodeFlags_DefaultOpen)
            if (open && ui:beginTable("Table", 3, ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable | ImGui.TableFlags_Borders | ImGui.TableFlags_SizingFixedFit | ImGui.TableFlags_NoSavedSettings))
            {
                ui:tableSetupColumn("One")
                ui:tableSetupColumn("Two")
                ui:tableSetupColumn("Three")
                ui:tableHeadersRow()
                for (int cell = 0 cell < 9 cell++)
                {
                    ui:tableNextColumn()
                    ui:text("this cell %d", cell)
                end
                ui:endTable()
            end
        end
        ui:treePop()
    end

    -- Demonstrate using Sorting facilities
    -- This is a simplified version of the "Advanced" example, where we mostly focus on the code necessary to handle sorting.
    -- Note that the "Advanced" example also showcase manually triggering a sort (e.g. if item quantities have been modified)
    static const char* template_items_names[] =
    {
        "Banana", "Apple", "Cherry", "Watermelon", "Grapefruit", "Strawberry", "Mango",
        "Kiwi", "Orange", "Pineapple", "Blueberry", "Plum", "Coconut", "Pear", "Apricot"
    end
    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Sorting"))
    {
        -- Create item list
        static ImVector<MyItem> items
        if (items.Size == 0)
        {
            items.resize(50, MyItem())
            for (int n = 0 n < items.Size n++)
            {
                const int template_n = n % IM_ARRAYSIZE(template_items_names)
                MyItem& item = items[n]
                item.ID = n
                item.Name = template_items_names[template_n]
                item.Quantity = (n * n - n) % 20 -- Assign default quantities
            end
        end

        -- Options
        static ImGui.TableFlags flags =
            ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable | ImGui.TableFlags_Sortable | ImGui.TableFlags_SortMulti
            | ImGui.TableFlags_RowBg | ImGui.TableFlags_BordersOuter | ImGui.TableFlags_BordersV | ImGui.TableFlags_NoBordersInBody
            | ImGui.TableFlags_ScrollY
        pushStyleCompact(ui)
        ui:checkboxFlags("ImGui.TableFlags_SortMulti", &flags, ImGui.TableFlags_SortMulti)
        ui:sameLine() helpMarker(ui, "When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).")
        ui:checkboxFlags("ImGui.TableFlags_SortTristate", &flags, ImGui.TableFlags_SortTristate)
        ui:sameLine() helpMarker(ui, "When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).")
        popStyleCompact(ui)

        if (ui:beginTable("table_sorting", 4, flags, ImVec2(0.0f, TEXT_BASE_HEIGHT * 15), 0.0f))
        {
            -- Declare columns
            -- We use the "user_id" parameter of TableSetupColumn() to specify a user id that will be stored in the sort specifications.
            -- This is so our sort function can identify a column given our own identifier. We could also identify them based on their index!
            -- Demonstrate using a mixture of flags among available sort-related flags:
            -- - ImGui.TableColumnFlags_DefaultSort
            -- - ImGui.TableColumnFlags_NoSort / ImGui.TableColumnFlags_NoSortAscending / ImGui.TableColumnFlags_NoSortDescending
            -- - ImGui.TableColumnFlags_PreferSortAscending / ImGui.TableColumnFlags_PreferSortDescending
            ui:tableSetupColumn("ID",       ImGui.TableColumnFlags_DefaultSort          | ImGui.TableColumnFlags_WidthFixed,   0.0f, MyItemColumnID_ID)
            ui:tableSetupColumn("Name",                                                  ImGui.TableColumnFlags_WidthFixed,   0.0f, MyItemColumnID_Name)
            ui:tableSetupColumn("Action",   ImGui.TableColumnFlags_NoSort               | ImGui.TableColumnFlags_WidthFixed,   0.0f, MyItemColumnID_Action)
            ui:tableSetupColumn("Quantity", ImGui.TableColumnFlags_PreferSortDescending | ImGui.TableColumnFlags_WidthStretch, 0.0f, MyItemColumnID_Quantity)
            ui:tableSetupScrollFreeze(0, 1) -- Make row always visible
            ui:tableHeadersRow()

            -- Sort our data if sort specs have been changed!
            if (ImGui.TableSortSpecs* sorts_specs = ui:tableGetSortSpecs())
                if (sorts_specs->SpecsDirty)
                {
                    MyItem::s_current_sort_specs = sorts_specs -- Store in variable accessible by the sort function.
                    if (items.Size > 1)
                        qsort(&items[0], (size_t)items.Size, sizeof(items[0]), MyItem::CompareWithSortSpecs)
                    MyItem::s_current_sort_specs = NULL
                    sorts_specs->SpecsDirty = false
                end

            -- Demonstrate using clipper for large vertical lists
            ImGuiListClipper clipper
            clipper.Begin(items.Size)
            while (clipper.Step())
                for (int row_n = clipper.DisplayStart row_n < clipper.DisplayEnd row_n++)
                {
                    -- Display a data item
                    MyItem* item = &items[row_n]
                    ui:pushID(item->ID)
                    ui:tableNextRow()
                    ui:tableNextColumn()
                    ui:text("%04d", item->ID)
                    ui:tableNextColumn()
                    ui:textUnformatted(item->Name)
                    ui:tableNextColumn()
                    ui:SmallButton("None")
                    ui:tableNextColumn()
                    ui:text("%d", item->Quantity)
                    ui:popID()
                end
            ui:endTable()
        end
        ui:treePop()
    end

    --ui:setNextItemOpen(true, ImGuiCond_Once) -- [DEBUG]
    if (open_action ~= -1)
        ui:setNextItemOpen(open_action ~= 0)
    if (ui:treeNode("Advanced"))
    {
        static ImGui.TableFlags flags =
            ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable | ImGui.TableFlags_Hideable
            | ImGui.TableFlags_Sortable | ImGui.TableFlags_SortMulti
            | ImGui.TableFlags_RowBg | ImGui.TableFlags_Borders | ImGui.TableFlags_NoBordersInBody
            | ImGui.TableFlags_ScrollX | ImGui.TableFlags_ScrollY
            | ImGui.TableFlags_SizingFixedFit

        enum ContentsType { CT_Text, CT_Button, CT_SmallButton, CT_FillButton, CT_Selectable, CT_SelectableSpanRow end
        static int contents_type = CT_SelectableSpanRow
        const char* contents_type_names[] = { "Text", "Button", "SmallButton", "FillButton", "Selectable", "Selectable (span row)" end
        static int freeze_cols = 1
        static int freeze_rows = 1
        static int items_count = IM_ARRAYSIZE(template_items_names) * 2
        static ImVec2 outer_size_value = ImVec2(0.0f, TEXT_BASE_HEIGHT * 12)
        static float row_min_height = 0.0f -- Auto
        static float inner_width_with_scroll = 0.0f -- Auto-extend
        static bool outer_size_enabled = true
        static bool show_headers = true
        static bool show_wrapped_text = false
        --static ImGuiTextFilter filter
        --ui:setNextItemOpen(true, ImGuiCond_Once) -- FIXME-TABLE: Enabling this results in initial clipped first pass on table which tend to affects column sizing
        if (ui:treeNode("Options"))
        {
            -- Make the UI compact because there are so many fields
            pushStyleCompact(ui)
            ui:pushItemWidth(TEXT_BASE_WIDTH * 28.0f)

            if (ui:treeNodeEx("Features:", ImGuitreeNodeFlags_DefaultOpen))
            {
                ui:checkboxFlags("ImGui.TableFlags_Resizable", &flags, ImGui.TableFlags_Resizable)
                ui:checkboxFlags("ImGui.TableFlags_Reorderable", &flags, ImGui.TableFlags_Reorderable)
                ui:checkboxFlags("ImGui.TableFlags_Hideable", &flags, ImGui.TableFlags_Hideable)
                ui:checkboxFlags("ImGui.TableFlags_Sortable", &flags, ImGui.TableFlags_Sortable)
                ui:checkboxFlags("ImGui.TableFlags_NoSavedSettings", &flags, ImGui.TableFlags_NoSavedSettings)
                ui:checkboxFlags("ImGui.TableFlags_ContextMenuInBody", &flags, ImGui.TableFlags_ContextMenuInBody)
                ui:treePop()
            end

            if (ui:treeNodeEx("Decorations:", ImGuitreeNodeFlags_DefaultOpen))
            {
                ui:checkboxFlags("ImGui.TableFlags_RowBg", &flags, ImGui.TableFlags_RowBg)
                ui:checkboxFlags("ImGui.TableFlags_BordersV", &flags, ImGui.TableFlags_BordersV)
                ui:checkboxFlags("ImGui.TableFlags_BordersOuterV", &flags, ImGui.TableFlags_BordersOuterV)
                ui:checkboxFlags("ImGui.TableFlags_BordersInnerV", &flags, ImGui.TableFlags_BordersInnerV)
                ui:checkboxFlags("ImGui.TableFlags_BordersH", &flags, ImGui.TableFlags_BordersH)
                ui:checkboxFlags("ImGui.TableFlags_BordersOuterH", &flags, ImGui.TableFlags_BordersOuterH)
                ui:checkboxFlags("ImGui.TableFlags_BordersInnerH", &flags, ImGui.TableFlags_BordersInnerH)
                ui:checkboxFlags("ImGui.TableFlags_NoBordersInBody", &flags, ImGui.TableFlags_NoBordersInBody) ui:sameLine() helpMarker(ui, "Disable vertical borders in columns Body (borders will always appears in Headers")
                ui:checkboxFlags("ImGui.TableFlags_NoBordersInBodyUntilResize", &flags, ImGui.TableFlags_NoBordersInBodyUntilResize) ui:sameLine() helpMarker(ui, "Disable vertical borders in columns Body until hovered for resize (borders will always appears in Headers)")
                ui:treePop()
            end

            if (ui:treeNodeEx("Sizing:", ImGuitreeNodeFlags_DefaultOpen))
            {
                EditTableSizingFlags(&flags)
                ui:sameLine() helpMarker(ui, "In the Advanced demo we override the policy of each column so those table-wide settings have less effect that typical.")
                ui:checkboxFlags("ImGui.TableFlags_NoHostExtendX", &flags, ImGui.TableFlags_NoHostExtendX)
                ui:sameLine() helpMarker(ui, "Make outer width auto-fit to columns, overriding outer_size.x value.\n\nOnly available when ScrollX/ScrollY are disabled and Stretch columns are not used.")
                ui:checkboxFlags("ImGui.TableFlags_NoHostExtendY", &flags, ImGui.TableFlags_NoHostExtendY)
                ui:sameLine() helpMarker(ui, "Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).\n\nOnly available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.")
                ui:checkboxFlags("ImGui.TableFlags_NoKeepColumnsVisible", &flags, ImGui.TableFlags_NoKeepColumnsVisible)
                ui:sameLine() helpMarker(ui, "Only available if ScrollX is disabled.")
                ui:checkboxFlags("ImGui.TableFlags_PreciseWidths", &flags, ImGui.TableFlags_PreciseWidths)
                ui:sameLine() helpMarker(ui, "Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.")
                ui:checkboxFlags("ImGui.TableFlags_NoClip", &flags, ImGui.TableFlags_NoClip)
                ui:sameLine() helpMarker(ui, "Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with ScrollFreeze options.")
                ui:treePop()
            end

            if (ui:treeNodeEx("Padding:", ImGuitreeNodeFlags_DefaultOpen))
            {
                ui:checkboxFlags("ImGui.TableFlags_PadOuterX", &flags, ImGui.TableFlags_PadOuterX)
                ui:checkboxFlags("ImGui.TableFlags_NoPadOuterX", &flags, ImGui.TableFlags_NoPadOuterX)
                ui:checkboxFlags("ImGui.TableFlags_NoPadInnerX", &flags, ImGui.TableFlags_NoPadInnerX)
                ui:treePop()
            end

            if (ui:treeNodeEx("Scrolling:", ImGuitreeNodeFlags_DefaultOpen))
            {
                ui:checkboxFlags("ImGui.TableFlags_ScrollX", &flags, ImGui.TableFlags_ScrollX)
                ui:sameLine()
                ui:SetNextItemWidth(ui:GetFrameHeight())
                ui:DragInt("freeze_cols", &freeze_cols, 0.2f, 0, 9, NULL, ImGuiSliderFlags_NoInput)
                ui:checkboxFlags("ImGui.TableFlags_ScrollY", &flags, ImGui.TableFlags_ScrollY)
                ui:sameLine()
                ui:SetNextItemWidth(ui:GetFrameHeight())
                ui:DragInt("freeze_rows", &freeze_rows, 0.2f, 0, 9, NULL, ImGuiSliderFlags_NoInput)
                ui:treePop()
            end

            if (ui:treeNodeEx("Sorting:", ImGuitreeNodeFlags_DefaultOpen))
            {
                ui:checkboxFlags("ImGui.TableFlags_SortMulti", &flags, ImGui.TableFlags_SortMulti)
                ui:sameLine() helpMarker(ui, "When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).")
                ui:checkboxFlags("ImGui.TableFlags_SortTristate", &flags, ImGui.TableFlags_SortTristate)
                ui:sameLine() helpMarker(ui, "When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).")
                ui:treePop()
            end

            if (ui:treeNodeEx("Other:", ImGuitreeNodeFlags_DefaultOpen))
            {
                ui:checkbox("show_headers", &show_headers)
                ui:checkbox("show_wrapped_text", &show_wrapped_text)

                ui:DragFloat2("##OuterSize", &outer_size_value.x)
                ui:sameLine(0.0f, ui:GetStyle().ItemInnerSpacing.x)
                ui:checkbox("outer_size", &outer_size_enabled)
                ui:sameLine()
                helpMarker(ui, "If scrolling is disabled (ScrollX and ScrollY not set):\n"
                    "- The table is output directly in the parent window.\n"
                    "- OuterSize.x < 0.0f will right-align the table.\n"
                    "- OuterSize.x = 0.0f will narrow fit the table unless there are any Stretch column.\n"
                    "- OuterSize.y then becomes the minimum size for the table, which will extend vertically if there are more rows (unless NoHostExtendY is set).")

                -- From a user point of view we will tend to use 'inner_width' differently depending on whether our table is embedding scrolling.
                -- To facilitate toying with this demo we will actually pass 0.0f to the beginTable() when ScrollX is disabled.
                ui:DragFloat("inner_width (when ScrollX active)", &inner_width_with_scroll, 1.0f, 0.0f, FLT_MAX)

                ui:DragFloat("row_min_height", &row_min_height, 1.0f, 0.0f, FLT_MAX)
                ui:sameLine() helpMarker(ui, "Specify height of the Selectable item.")

                ui:DragInt("items_count", &items_count, 0.1f, 0, 9999)
                ui:Combo("items_type (first column)", &contents_type, contents_type_names, IM_ARRAYSIZE(contents_type_names))
                --filter.Draw("filter")
                ui:treePop()
            end

            ui:popItemWidth()
            popStyleCompact(ui)
            ui:Spacing()
            ui:treePop()
        end

        -- Recreate/reset item list if we changed the number of items
        static ImVector<MyItem> items
        static ImVector<int> selection
        static bool items_need_sort = false
        if (items.Size ~= items_count)
        {
            items.resize(items_count, MyItem())
            for (int n = 0 n < items_count n++)
            {
                const int template_n = n % IM_ARRAYSIZE(template_items_names)
                MyItem& item = items[n]
                item.ID = n
                item.Name = template_items_names[template_n]
                item.Quantity = (template_n == 3) ? 10 : (template_n == 4) ? 20 : 0 -- Assign default quantities
            end
        end

        const ImDrawList* parent_draw_list = ui:GetWindowDrawList()
        const int parent_draw_list_draw_cmd_count = parent_draw_list->CmdBuffer.Size
        ImVec2 table_scroll_cur, table_scroll_max -- For debug display
        const ImDrawList* table_draw_list = NULL  -- "

        const float inner_width_to_use = (flags & ImGui.TableFlags_ScrollX) ? inner_width_with_scroll : 0.0f
        if (ui:beginTable("table_advanced", 6, flags, outer_size_enabled ? outer_size_value : ImVec2(0, 0), inner_width_to_use))
        {
            -- Declare columns
            -- We use the "user_id" parameter of TableSetupColumn() to specify a user id that will be stored in the sort specifications.
            -- This is so our sort function can identify a column given our own identifier. We could also identify them based on their index!
            ui:tableSetupColumn("ID",           ImGui.TableColumnFlags_DefaultSort | ImGui.TableColumnFlags_WidthFixed | ImGui.TableColumnFlags_NoHide, 0.0f, MyItemColumnID_ID)
            ui:tableSetupColumn("Name",         ImGui.TableColumnFlags_WidthFixed, 0.0f, MyItemColumnID_Name)
            ui:tableSetupColumn("Action",       ImGui.TableColumnFlags_NoSort | ImGui.TableColumnFlags_WidthFixed, 0.0f, MyItemColumnID_Action)
            ui:tableSetupColumn("Quantity",     ImGui.TableColumnFlags_PreferSortDescending, 0.0f, MyItemColumnID_Quantity)
            ui:tableSetupColumn("Description",  (flags & ImGui.TableFlags_NoHostExtendX) ? 0 : ImGui.TableColumnFlags_WidthStretch, 0.0f, MyItemColumnID_Description)
            ui:tableSetupColumn("Hidden",       ImGui.TableColumnFlags_DefaultHide | ImGui.TableColumnFlags_NoSort)
            ui:tableSetupScrollFreeze(freeze_cols, freeze_rows)

            -- Sort our data if sort specs have been changed!
            ImGui.TableSortSpecs* sorts_specs = ui:tableGetSortSpecs()
            if (sorts_specs && sorts_specs->SpecsDirty)
                items_need_sort = true
            if (sorts_specs && items_need_sort && items.Size > 1)
            {
                MyItem::s_current_sort_specs = sorts_specs -- Store in variable accessible by the sort function.
                qsort(&items[0], (size_t)items.Size, sizeof(items[0]), MyItem::CompareWithSortSpecs)
                MyItem::s_current_sort_specs = NULL
                sorts_specs->SpecsDirty = false
            end
            items_need_sort = false

            -- Take note of whether we are currently sorting based on the Quantity field,
            -- we will use this to trigger sorting when we know the data of this column has been modified.
            const bool sorts_specs_using_quantity = (ui:tableGetColumnFlags(3) & ImGui.TableColumnFlags_IsSorted) ~= 0

            -- Show headers
            if (show_headers)
                ui:tableHeadersRow()

            -- Show data
            -- FIXME-TABLE FIXME-NAV: How we can get decent up/down even though we have the buttons here?
            ui:pushButtonRepeat(true)
#if 1
            -- Demonstrate using clipper for large vertical lists
            ImGuiListClipper clipper
            clipper.Begin(items.Size)
            while (clipper.Step())
            {
                for (int row_n = clipper.DisplayStart row_n < clipper.DisplayEnd row_n++)
#else
            -- Without clipper
            {
                for (int row_n = 0 row_n < items.Size row_n++)
#endif
                {
                    MyItem* item = &items[row_n]
                    --if (!filter.PassFilter(item->Name))
                    --    continue

                    const bool item_is_selected = selection.contains(item->ID)
                    ui:pushID(item->ID)
                    ui:tableNextRow(ImGui.TableRowFlags_None, row_min_height)
                    ui:tableNextColumn()

                    -- For the demo purpose we can select among different type of items submitted in the first column
                    char label[32]
                    sprintf(label, "%04d", item->ID)
                    if (contents_type == CT_Text)
                        ui:textUnformatted(label)
                    else if (contents_type == CT_Button)
                        ui:button(label)
                    else if (contents_type == CT_SmallButton)
                        ui:SmallButton(label)
                    else if (contents_type == CT_FillButton)
                        ui:button(label, ImVec2(-FLT_MIN, 0.0f))
                    else if (contents_type == CT_Selectable || contents_type == CT_SelectableSpanRow)
                    {
                        ImGuiSelectableFlags selectable_flags = (contents_type == CT_SelectableSpanRow) ? ImGuiSelectableFlags_SpanAllColumns | ImGuiSelectableFlags_AllowItemOverlap : ImGuiSelectableFlags_None
                        if (ui:Selectable(label, item_is_selected, selectable_flags, ImVec2(0, row_min_height)))
                        {
                            if (ui:GetIO().KeyCtrl)
                            {
                                if (item_is_selected)
                                    selection.find_erase_unsorted(item->ID)
                                else
                                    selection.push_back(item->ID)
                            end
                            else
                            {
                                selection.clear()
                                selection.push_back(item->ID)
                            end
                        end
                    end

                    if (ui:tableNextColumn())
                        ui:textUnformatted(item->Name)

                    -- Here we demonstrate marking our data set as needing to be sorted again if we modified a quantity,
                    -- and we are currently sorting on the column showing the Quantity.
                    -- To avoid triggering a sort while holding the button, we only trigger it when the button has been released.
                    -- You will probably need a more advanced system in your code if you want to automatically sort when a specific entry changes.
                    if (ui:tableNextColumn())
                    {
                        if (ui:SmallButton("Chop")) { item->Quantity += 1 end
                        if (sorts_specs_using_quantity && ui:IsItemDeactivated()) { items_need_sort = true end
                        ui:sameLine()
                        if (ui:SmallButton("Eat")) { item->Quantity -= 1 end
                        if (sorts_specs_using_quantity && ui:IsItemDeactivated()) { items_need_sort = true end
                    end

                    if (ui:tableNextColumn())
                        ui:text("%d", item->Quantity)

                    ui:tableNextColumn()
                    if (show_wrapped_text)
                        ui:textWrapped("Lorem ipsum dolor sit amet")
                    else
                        ui:text("Lorem ipsum dolor sit amet")

                    if (ui:tableNextColumn())
                        ui:text("1234")

                    ui:popID()
                end
            end
            ui:popButtonRepeat()

            -- Store some info to display debug details below
            table_scroll_cur = ImVec2(ui:GetScrollX(), ui:GetScrollY())
            table_scroll_max = ImVec2(ui:GetScrollMaxX(), ui:GetScrollMaxY())
            table_draw_list = ui:GetWindowDrawList()
            ui:endTable()
        end
        ui:treePop()
    end
	]]

    ui:popID()

    -- showDemoWindowColumns() TODO

    if (disable_indent) then
        ui:popStyleVar()
	end
end