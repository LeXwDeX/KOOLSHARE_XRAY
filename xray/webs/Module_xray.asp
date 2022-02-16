<title>xray</title>
<content>
<script type="text/javascript" src="/js/jquery.min.js"></script>
<script type="text/javascript" src="/js/tomato.js"></script>
<script type="text/javascript" src="/js/advancedtomato.js"></script>
<style type="text/css">
.box, #xray_tabs {
	min-width:720px;
}
</style>
	<script type="text/javascript">
		var dbus;
		get_arp_list();
		get_dbus_data();
		var _responseLen;
		var noChange = 0;
		var x = 4;
		var status_time = 1;
		var option_mode = [['Vless', 'Vless']];
		var option_auth = [['1', '无验证'], ['2', '使用用户名密码验证']];
		var option_ss_method = [['aes-128-cfb', 'aes-128-cfb'], ['aes-256-cfb', 'aes-256-cfb'], ['chacha20', 'chacha20'], ['chacha20-ietf', 'chacha20-ietf'], ['chacha20-poly1305', 'chacha20-poly1305'], ['chacha20-ietf-poly1305', 'chacha20-ietf-poly1305'], ['aes-128-gcm', 'aes-128-gcm'], ['aes-256-gcm', 'aes-256-gcm']];
		var option_acl_mode = [['0', '不代理'], ['1', 'gfwlist黑名单'], ['2', '大陆白名单'], ['3', '游戏模式'], ['4', '全局模式']];
		var option_acl_mode_name = ['不代理', 'gfwlist黑名单', '大陆白名单', '游戏模式', '全局模式'];
		var option_dns_china = [['1', '运营商DNS【自动获取】'],  ['2', '阿里DNS1【223.5.5.5】'],  ['3', '阿里DNS2【223.6.6.6】'],  ['4', '114DNS1【114.114.114.114】'],  
								['5', '114DNS1【114.114.115.115】'],  ['6', 'cnnic DNS【1.2.4.8】'],  ['7', 'cnnic DNS【210.2.4.8】'],  ['8', 'oneDNS1【112.124.47.27】'],  
								['9', 'oneDNS2【114.215.126.16】'],  ['10', '百度DNS【180.76.76.76】'],  ['11', 'DNSpod DNS【119.29.29.29】'],  ['12', '自定义']];
		var option_xray_dns_foreign = [['2', 'google dns\[8.8.8.8\]'], ['3', 'google dns\[8.8.4.4\]'], ['1', 'OpenDNS\[208.67.220.220\]'], ['4', '自定义']];
		var option_dns_foreign = [['1', 'xray_dns']];
		var option_server_list = [];
		var option_arp_list = [];
		var option_arp_local = [];
		var option_arp_web = [];
		var softcenter = 0;
		var option_day_time = [["7", "每天"], ["1", "周一"], ["2", "周二"], ["3", "周三"], ["4", "周四"], ["5", "周五"], ["6", "周六"], ["0", "周日"]];
		var option_time_mod = [["1", "自动重启"], ["2", "切换服务器"]];
		var option_time_hour = [];
		for(var i = 0; i < 24; i++){
			option_time_hour[i] = [i, i + "点"];
		}

		var option_time_minute = [];
		for(var i = 0; i < 59; i++){
			option_time_minute[i] = [i, i + "分"];
		}

		var option_time_watch = [];
		for(var i = 1; i < 60; i++){
			option_time_watch[i-1] = [i, i + "分钟"];
		}

		if (typeof btoa == "Function") {
			Base64 = {
				encode: function(e) {
					return btoa(e);
				},
				decode: function(e) {
					return atob(e);
				}
			};
		} else {
			Base64 = {
				_keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
				encode: function(e) {
					var t = "";
					var n, r, i, s, o, u, a;
					var f = 0;
					e = Base64._utf8_encode(e);
					while (f < e.length) {
						n = e.charCodeAt(f++);
						r = e.charCodeAt(f++);
						i = e.charCodeAt(f++);
						s = n >> 2;
						o = (n & 3) << 4 | r >> 4;
						u = (r & 15) << 2 | i >> 6;
						a = i & 63;
						if (isNaN(r)) {
							u = a = 64
						} else if (isNaN(i)) {
							a = 64
						}
						t = t + this._keyStr.charAt(s) + this._keyStr.charAt(o) + this._keyStr.charAt(u) + this._keyStr.charAt(a)
					}
					return t
				},
				decode: function(e) {
					var t = "";
					var n, r, i;
					var s, o, u, a;
					var f = 0;
					if (typeof(e) == "undefined"){
						return t = "";
					}
					e = e.replace(/[^A-Za-z0-9\+\/\=]/g, "");
					while (f < e.length) {
						s = this._keyStr.indexOf(e.charAt(f++));
						o = this._keyStr.indexOf(e.charAt(f++));
						u = this._keyStr.indexOf(e.charAt(f++));
						a = this._keyStr.indexOf(e.charAt(f++));
						n = s << 2 | o >> 4;
						r = (o & 15) << 4 | u >> 2;
						i = (u & 3) << 6 | a;
						t = t + String.fromCharCode(n);
						if (u != 64) {
							t = t + String.fromCharCode(r)
						}
						if (a != 64) {
							t = t + String.fromCharCode(i)
						}
					}
					t = Base64._utf8_decode(t);
					return t
				},
				_utf8_encode: function(e) {
					e = e.replace(/\r\n/g, "\n");
					var t = "";
					for (var n = 0; n < e.length; n++) {
						var r = e.charCodeAt(n);
						if (r < 128) {
							t += String.fromCharCode(r)
						} else if (r > 127 && r < 2048) {
							t += String.fromCharCode(r >> 6 | 192);
							t += String.fromCharCode(r & 63 | 128)
						} else {
							t += String.fromCharCode(r >> 12 | 224);
							t += String.fromCharCode(r >> 6 & 63 | 128);
							t += String.fromCharCode(r & 63 | 128)
						}
					}
					return t
				},
				_utf8_decode: function(e) {
					var t = "";
					var n = 0;
					var r = c1 = c2 = 0;
					while (n < e.length) {
						r = e.charCodeAt(n);
						if (r < 128) {
							t += String.fromCharCode(r);
							n++
						} else if (r > 191 && r < 224) {
							c2 = e.charCodeAt(n + 1);
							t += String.fromCharCode((r & 31) << 6 | c2 & 63);
							n += 2
						} else {
							c2 = e.charCodeAt(n + 1);
							c3 = e.charCodeAt(n + 2);
							t += String.fromCharCode((r & 15) << 12 | (c2 & 63) << 6 | c3 & 63);
							n += 3
						}
					}
					return t
				}
			}
		}
		function createFormFields(data, settings) {
			var id, id1, common, output, form = '';
			var s = $.extend({
					// Defaults
					'align': 'left',
					'grid': ['col-sm-3', 'col-sm-9']
				},
				settings);
			// Loop through array
			$.each(data,
				function(key, v) {
					if (!v) {
						form += '<br />';
						return;
					}
					if (v.ignore) return;
					form += '<fieldset' + ((v.rid) ? ' id="' + v.rid + '"' : '') + ((v.hidden) ? ' style="display: none;"' : '') + '>';
					if (v.help) {
						v.title += ' (<i data-toggle="tooltip" class="icon-info icon-normal" title="' + v.help + '"></i>)';
					}
					if (v.text) {
						if (v.title) {
							form += '<label class="' + s.grid[0] + ' ' + ((s.align == 'center') ? 'control-label' : 'control-left-label') + '">' + v.title + '</label><div class="' + s.grid[1] + ' text-block">' + v.text + '</div></fieldset>';
						} else {
							form += '<label class="' + s.grid[0] + ' ' + ((s.align == 'center') ? 'control-label' : 'control-left-label') + '">' + v.text + '</label></fieldset>';
						}
						return;
					}
					if (v.multi) multiornot = v.multi;
					else multiornot = [v];
					output = '';
					$.each(multiornot,
						function(key, f) {
							if ((f.type == 'radio') && (!f.id)) id = '_' + f.name + '_' + i;
							else id = (f.id ? f.id : ('_' + f.name));
							if (id1 == '') id1 = id;
							common = ' onchange="verifyFields(this, 1)" id="' + id + '"';
							if (f.size > 65) common += ' style="width: 100%; display: block;"';
							if (f.hidden) common += ' style="display:none;"'; //add by sadog
							if (f.attrib) common += ' ' + f.attrib;
							name = f.name ? (' name="' + f.name + '"') : '';
							// Prefix
							if (f.prefix) output += f.prefix;
							switch (f.type) {
								case 'checkbox':
									output += '<div class="checkbox c-checkbox"><label><input class="custom" type="checkbox"' + name + (f.value ? ' checked' : '') + ' onclick="verifyFields(this, 1)"' + common + '>\
		<span></span> ' + (f.suffix ? f.suffix : '') + '</label></div>';
									break;
								case 'radio':
									output += '<div class="radio c-radio"><label><input class="custom" type="radio"' + name + (f.value ? ' checked' : '') + ' onclick="verifyFields(this, 1)"' + common + '>\
		<span></span> ' + (f.suffix ? f.suffix : '') + '</label></div>';
									break;
								case 'password':
									if (f.peekaboo) {
										switch (get_config('web_pb', '1')) {
											case '0':
												f.type = 'text';
											case '2':
												f.peekaboo = 0;
												break;
										}
									}
									if (f.type == 'password') {
										common += ' autocomplete="off"';
										if (f.peekaboo) common += ' onfocus=\'peekaboo("' + id + '",1)\' onclick=\'this.removeAttribute(' + 'readonly' + ');\' readonly="true"';
									}
									// drop
								case 'text':
									output += '<input type="' + f.type + '"' + name + ' value="' + escapeHTML(UT(f.value)) + '" maxlength=' + f.maxlen + (f.size ? (' size=' + f.size) : '') + (f.style ? (' style=' + f.style) : '') + (f.onblur ? (' onblur=' + f.onblur) : '') + common + '>';
									break;
								case 'select':
									output += '<select' + name + (f.style ? (' style=' + f.style) : '') + common + '>';
									for (optsCount = 0; optsCount < f.options.length; ++optsCount) {
										a = f.options[optsCount];
										if (a.length == 1) a.push(a[0]);
										output += '<option value="' + a[0] + '"' + ((a[0] == f.value) ? ' selected' : '') + '>' + a[1] + '</option>';
									}
									output += '</select>';
									break;
								case 'textarea':
									output += '<textarea ' + 'spellcheck=\"false\"' + (f.style ? (' style="' + f.style + '" ') : '') + name + common + (f.wrap ? (' wrap=' + f.wrap) : '') + '>' + escapeHTML(UT(f.value)) + '</textarea>';
									break;
								default:
									if (f.custom) output += f.custom;
									break;
							}
							if (f.suffix && (f.type != 'checkbox' && f.type != 'radio')) output += '<span class="help-block">' + f.suffix + '</span>';
						});
					if (id1 != '') form += '<label class="' + s.grid[0] + ' ' + ((s.align == 'center') ? 'control-label' : 'control-left-label') + '" for="' + id + '">' + v.title + '</label><div class="' + s.grid[1] + '">' + output;
					else form += '<label>' + v.title + '</label>';
					form += '</div></fieldset>';
				});
			return form;
		}
		//============================================
		var xray_server = new TomatoGrid();
		xray_server.dataToView = function( data ) {
			if (data[0]){
				return [ data[0], data[1], "******" ];
			}else{
				if (data[1]){
					return [ data[1], data[1], "******" ];
				}else{
					if (data[2]){
						return [ data[2], data[1], "******" ];
					}
				}
			}
		}
		xray_server.fieldValuesToData = function( row ) {
			var f = fields.getAll( row );
			if (f[0].value){
				return [ f[0].value, f[1].value, f[2].value ];
			}else{
				if (f[1].value){
					return [ f[1].value, f[1].value, f[2].value ];
				}else{
					if (f[2].value){
						return [ f[2].value, f[1].value, f[2].value ];
					}
				}
			}
		}
    	xray_server.onChange = function(which, cell) {
    	    return this.verifyFields((which == 'new') ? this.newEditor: this.editor, true, cell);
    	}
		xray_server.onAdd = function() {
			var data;
			this.moving = null;
			this.rpHide();
			if (!this.verifyFields(this.newEditor, false)) return;
			data = this.fieldValuesToData(this.newEditor);
			this.insertData(1, data);
			this.disableNewEditor(false);
			this.resetNewEditor();
		}
		xray_server.rpDel = function(b) {
			b = PR(b);
			TGO(b).moving = null;
			b.parentNode.removeChild(b);
			this.recolor();
			this.rpHide()
		}
		xray_server.resetNewEditor = function() {
			var f;
			f = fields.getAll( this.newEditor );
			ferror.clearAll( f );
			f[ 0 ].value = '';
			f[ 1 ].value = ''
			f[ 2 ].value = ''
		}
		xray_server.footerSet = function(c, b) {
			var f, d;
			elem.remove(this.footer);
			this.footer = f = this._insert(-1, c, b);
			//f.className = "alert alert-info";
			for (d = 0; d < f.cells.length; ++d) {
				f.cells[d].cellN = d;
				f.cells[d].onclick = function() {
					TGO(this).footerClick(this)
				}
			}
			return f
		}
		xray_server.dataToFieldValues = function (data) {
			return [data[0], data[1], data[2]];
		}
		xray_server.setup = function() {
			this.init( 'xray_server_pannel', '', 254, [
			{ type: 'text',maxlen:3},	//name
			{ type: 'text',maxlen:30},	//name
			{ type: 'text',maxlen:9999}	//name
			] );
			this.headerSet( [ 'ID', 'xray服务器标签', 'xray配置文件'] );						
			for ( var i = 1; i <= dbus["xray_server_node_max"]; i++){
				var t = [
						String(i),
						dbus["xray_server_tag_" + i ], 
						Base64.decode(dbus["xray_server_config_" + i ])
						]
				if ( t.length == 3 ) this.insertData( -1, t );
			}
			this.recolor();
			this.showNewEditor();
			this.resetNewEditor();
		}
		//============================================
		var xray_acl = new TomatoGrid();
		xray_acl.dataToView = function( data ) {
			if (data[0]){
				return [ "【" + data[0] + "】", data[1], data[2], option_acl_mode_name[data[3]] ];
			}else{
				if (data[1]){
					return [ "【" + data[1] + "】", data[1], data[2], option_acl_mode_name[data[3]]];
				}else{
					if (data[2]){
						return [ "【" + data[2] + "】", data[1], data[2], option_acl_mode_name[data[3]] ];
					}
				}
			}
		}
		xray_acl.fieldValuesToData = function( row ) {
			var f = fields.getAll( row );
			if (f[0].value){
				return [ f[0].value, f[1].value, f[2].value, f[3].value ];
			}else{
				if (f[1].value){
					return [ f[1].value, f[1].value, f[2].value, f[3].value ];
				}else{
					if (f[2].value){
						return [ f[2].value, f[1].value, f[2].value, f[3].value ];
					}
				}
			}
		}
    	xray_acl.onChange = function(which, cell) {
    	    return this.verifyFields((which == 'new') ? this.newEditor: this.editor, true, cell);
    	}
		xray_acl.verifyFields = function( row, quiet,cell ) {
			var f = fields.getAll( row );
			// fill the ip and mac when chose the name
			if ( $(cell).attr("id") == "_[object HTMLTableElement]_1" ) {
				if (f[0].value){
					f[1].value = option_arp_list[f[0].selectedIndex][2];
					f[2].value = option_arp_list[f[0].selectedIndex][3];
				}
			}

			//check if ip and mac column correct
			if (f[1].value && !f[2].value){
				return v_ip( f[1], quiet );
			}
			if (!f[1].value && f[2].value){
				return v_mac( f[2], quiet );
			}
			if (f[1].value && f[2].value){
				return v_ip( f[1], quiet ) || v_mac( f[2], quiet );
			}
		}
		xray_acl.alter_txt = function() {
			if (this.tb.rows.length == "4"){
				$('#footer_ip').html("<i>全部主机 - ip</i>")
				$('#footer_mac').html("<i>全部主机 - mac</i>")
			}else{
				$('#footer_ip').html("<i>其它主机 - ip</i>")
				$('#footer_mac').html("<i>其它主机 - mac</i>")
			}
		}
		xray_acl.onAdd = function() {
			var data;
			this.moving = null;
			this.rpHide();
			if (!this.verifyFields(this.newEditor, false)) return;
			data = this.fieldValuesToData(this.newEditor);
			this.insertData(1, data);
			this.disableNewEditor(false);
			this.resetNewEditor();
			this.alter_txt(); // added by sadog
		}
		xray_acl.rpDel = function(b) {
			b = PR(b);
			TGO(b).moving = null;
			b.parentNode.removeChild(b);
			this.recolor();
			this.rpHide()
			this.alter_txt(); // added by sadog
		}
		xray_acl.resetNewEditor = function() {
			var f;
			f = fields.getAll( this.newEditor );
			ferror.clearAll( f );
			f[ 0 ].value = '';
			f[ 1 ].value   = '';
			f[ 2 ].value   = '';
			f[ 3 ].value   = '1';
		}
		xray_acl.footerSet = function(c, b) {
			var f, d;
			elem.remove(this.footer);
			this.footer = f = this._insert(-1, c, b);
			//f.className = "alert alert-info";
			for (d = 0; d < f.cells.length; ++d) {
				f.cells[d].cellN = d;
				f.cells[d].onclick = function() {
					TGO(this).footerClick(this)
				}
			}
			return f
		}
		xray_acl.dataToFieldValues = function (data) {
			return [data[0], data[1], data[2], data[3]];
		}
		xray_acl.setup = function() {
			this.init( 'xray_acl_pannel', '', 254, [
			{ type: 'select',maxlen:20,options:option_arp_list},	//name
			{ type: 'text',maxlen:20},	//name
			{ type: 'text',maxlen:20},	//name
			{ type: 'select',maxlen:20,options:option_acl_mode}	//control
			] );
			this.headerSet( [ '主机别名', '主机IP地址', 'MAC地址', '访问控制'] );
			if (typeof(dbus["xray_acl_node_max"]) == "undefined"){
				this.footerSet( [ '<small id="footer_name" style="color:#1bbf35"><i>缺省规则</i></small>','<small id="footer_ip" style="color:#1bbf35"><i>全部主机 - ip</i></small>','<small id="footer_mac" style="color:#1bbf35"><i>全部主机 - mac</small></i>','<select id="_xray_acl_default_mode1" name="xray_acl_default_mode1" style="border: 0px solid #222;background: transparent;margin-left:-4px;padding:-0 -0;height:16px;" onchange="verifyFields(this, 1)"><option value="0">不代理</option><option value="1">gfwlist黑名单</option><option value="2">大陆白名单</option><option value="3">游戏模式</option><option value="4">全局模式</option></select>']);
			}else{
				this.footerSet( [ '<small id="footer_name" style="color:#1bbf35"><i>缺省规则</i></small>','<small id="footer_ip" style="color:#1bbf35"><i>其它主机 - ip</i></small>','<small id="footer_mac" style="color:#1bbf35"><i>其它主机 - mac</small></i>','<select id="_xray_acl_default_mode1" name="xray_acl_default_mode1" style="border: 0px solid #222;background: transparent;margin-left:-4px;padding:-0 -0;height:16px;" onchange="verifyFields(this, 1)"><option value="0">不代理</option><option value="1">gfwlist黑名单</option><option value="2">大陆白名单</option><option value="3">游戏模式</option><option value="4">全局模式</option></select>']);
			}
			
			if(typeof(dbus["xray_acl_default_mode"]) != "undefined" ){
				E("_xray_acl_default_mode1").value = dbus["xray_acl_default_mode"];
			}else{
				E("_xray_acl_default_mode1").value = 1;
			}
			
			for ( var i = 1; i <= dbus["xray_acl_node_max"]; i++){
				var t = [dbus["xray_acl_name_" + i ], 
						dbus["xray_acl_ip_" + i ]  || "",
						dbus["xray_acl_mac_" + i ]  || "",
						dbus["xray_acl_mode_" + i ]]
				if ( t.length == 4 ) this.insertData( -1, t );
			}
			this.recolor();
			this.showNewEditor();
			this.resetNewEditor();
		}
		//============================================
		function init_xray(){
			tabSelect('app1');
			verifyFields();
			xray_server.setup();
			$("#_xray_basic_log").click(
				function() {
					x = 10000000;
			});
			show_hide_panel();
			set_version();
			auto_node_set();
			//version_show();
			setTimeout("get_run_status();", 2000);
		}

		function set_version(){
			$('#_xray_version').html( '<font color="#1bbf35">xray for openwrt - ' + (dbus["xray_version"]  || "") + '</font>' );
		}

		function get_dbus_data(){
			$.ajax({
			  	type: "GET",
			 	url: "/_api/xray",
			  	dataType: "json",
			  	async:false,
			 	success: function(data){
			 	 	dbus = data.result[0];
			  	}
			});
		}
		
		function get_run_status(){
			if (status_time > 99999){
				E("_xray_basic_status_foreign").innerHTML = "暂停获取状态...";
				E("_xray_basic_status_china").innerHTML = "暂停获取状态...";
				return false;
			}
			var id1 = parseInt(Math.random() * 100000000);
			var postData1 = {"id": id1, "method": "xray_status.sh", "params":[2], "fields": ""};
			$.ajax({
				type: "POST",
				url: "/_api/",
				data: JSON.stringify(postData1),
				dataType: "json",
				success: function(response){
					if(softcenter == 1){
						return false;
					}
					++status_time;
					if (response.result == '-2'){
						E("_xray_basic_status_foreign").innerHTML = "获取运行状态失败！";
						E("_xray_basic_status_china").innerHTML = "获取运行状态失败！";
						setTimeout("get_run_status();", 5000);
					}else{
						if(dbus["xray_basic_enable"] != "1"){
							E("_xray_basic_status_foreign").innerHTML = "国外链接 - 尚未提交，暂停获取状态！";
							E("_xray_basic_status_china").innerHTML = "国内链接 - 尚未提交，暂停获取状态！";
						}else{
							E("_xray_basic_status_foreign").innerHTML = response.result.split("@@")[0];
							E("_xray_basic_status_china").innerHTML = response.result.split("@@")[1];
						}
						setTimeout("get_run_status();", 5000);
					}
				},
				error: function(){
					if(softcenter == 1){
						return false;
					}
					E("_xray_basic_status_foreign").innerHTML = "获取运行状态失败！";
					E("_xray_basic_status_china").innerHTML = "获取运行状态失败！";
					setTimeout("get_run_status();", 5000);
				}
			});
		}

		function get_arp_list(){
			var id5 = parseInt(Math.random() * 100000000);
			var postData1 = {"id": id5, "method": "xray_getarp.sh", "params":[], "fields": ""};
			$.ajax({
				type: "POST",
				url: "/_api/",
				async:true,
				cache:false,
				data: JSON.stringify(postData1),
				dataType: "json",
				success: function(response){
					if (response.result != "-1"){
						var s2 = response.result.split( '>' );
						for ( var i = 0; i < s2.length; ++i ) {
							option_arp_local[i] = [s2[ i ].split( '<' )[0], "【" + s2[ i ].split( '<' )[0] + "】", s2[ i ].split( '<' )[1], s2[ i ].split( '<' )[2]];
						}
						var node_acl = parseInt(dbus["xray_acl_node_max"]) || 0;
						for ( var i = 0; i < node_acl; ++i ) {
							option_arp_web[i] = [dbus["xray_acl_name_" + (i + 1)], "【" + dbus["xray_acl_name_" + (i + 1)] + "】", dbus["xray_acl_ip_" + (i + 1)], dbus["xray_acl_mac_" + (i + 1)]];
						}			
						option_arp_list = unique_array(option_arp_local.concat( option_arp_web ));
						xray_acl.setup();
					}
				},
				error:function(){
					xray_acl.setup();
				},
				timeout:1000
			});
		}
		function unique_array(array){
			var r = [];
			for(var i = 0, l = array.length; i < l; i++) {
				for(var j = i + 1; j < l; j++)
				if (array[i][0] === array[j][0]) j = ++i;
					r.push(array[i]);
			}
			return r.sort();;
		}

		function show_hide_panel(){
			var a  = E('_xray_basic_enable').checked;
			elem.display('xray_status_pannel', a);
			elem.display('xray_tabs', a);
			elem.display('xray_basic_tab', a);
		}

		function verifyFields(r){
			// pannel1: when node changed, the main pannel element and other element should be changed, too.
			if ( $(r).attr("id") == "_xray_basic_type" ) {
				join_node();
			}

			if ( $(r).attr("id") == "_xray_basic_server" ) {
				auto_node_set();
			}

			if (E("_xray_dns_plan").value == "1"){
				$('#_xray_dns_plan_txt').html("国外dns解析gfwlist名单内的国外域名，剩下的域名用国内dns解析。 ")
			}else if (E("_xray_dns_plan").value == "2"){
				$('#_xray_dns_plan_txt').html("国内dns解析cdn名单内的国内域名用，剩下的域名用国外dns解析。<font color='#FF3300'>推荐！</font> ")
			}
			// when check/uncheck xray_switch
			var a  = E('_xray_basic_enable').checked;
			if ( $(r).attr("id") == "_xray_basic_enable" ) {
				if(a){
					elem.display('xray_status_pannel', a);
					elem.display('xray_tabs', a);
					tabSelect('app1')
				}else{
					tabSelect('fuckapp')
				}
			}
			// change main mode adn acl mode
			if ( $(r).attr("id") == "_xray_acl_default_mode" ) {
				E("_xray_acl_default_mode1").value = E("_xray_acl_default_mode").value;
			}
			if ( $(r).attr("id") == "_xray_acl_default_mode1" ) {
				E("_xray_acl_default_mode").value = E("_xray_acl_default_mode1").value;
			}

			// dns			
			var b  = E('_xray_dns_china').value == '12';
			elem.display('_xray_dns_china_user', b);
			
			var c  = E('_xray_dns_foreign').value == '4';
			elem.display('_xray_dns_foreign_user', c);

			//switch
			var d  = E('_xray_basic_cron').checked;
			elem.display(PR('_xray_basic_cron_enablehour'), d);
			elem.display(PR('_xray_basic_cron_enableminute'), d);
			elem.display(PR('_xray_basic_cron_disablehour'), d);
			elem.display(PR('_xray_basic_cron_disableminute'), d);

			//service
			var f1  = E('_xray_basic_socks').checked;
			var f2  = E('_xray_basic_http').checked;
			var f3  = E('_xray_basic_ss').checked;
			var f4  = E('_xray_service_auth').value == '2';
			elem.display(PR('_xray_service_auth'), f1||f2);
			elem.display(PR('_xray_service_sspasswd'), f3);
			elem.display(PR('_xray_service_passwd'), f4);
			
			//rule
			var l1  = E('_xray_basic_rule_update').value == '1';
			elem.display('_xray_basic_rule_update_day', l1);
			elem.display('_xray_basic_rule_update_hr', l1);
			elem.display(elem.parentElem('_xray_basic_gfwlist_update', 'DIV'), l1);
			elem.display('_xray_basic_gfwlist_update_txt', l1);
			elem.display(elem.parentElem('_xray_basic_chnroute_update', 'DIV'), l1);
			elem.display('_xray_basic_chnroute_update_txt', l1);
			elem.display(elem.parentElem('_xray_basic_cdn_update', 'DIV'), l1);
			elem.display('_xray_basic_cdn_update_txt', l1);

			// when check/uncheck xray_switch
			var n  = E('_xray_basic_node_update').checked;
			elem.display('_xray_basic_node_update_hr', n);
			elem.display('_xray_basic_node_update_day', n);
			
			return true;
		}

		function auto_node_set(){
			var n1 = (E('_xray_basic_type').value == '1');
			if (n1){
				var n2 = (E('_xray_basic_server').options[E('_xray_basic_server').selectedIndex].innerText == "新增配置");
				elem.display(PR('_xray_basic_tag'), n2);
				var nid = E('_xray_basic_server').value
				E("_xray_basic_config").value = Base64.decode(dbus["xray_server_config_" + nid ])
				if (!n2){
					E('_xray_basic_tag').value = ""
				}else{
					E('_xray_basic_config').value = ""
				}			
			}else{
				var nid = E('_xray_basic_server').value
				elem.display(PR('_xray_basic_tag'), false);
				E("_xray_basic_config").value = Base64.decode(dbus["xray_sub_config_" + nid ])			
			}
			//console.log(n3);
		}
		
		function join_node(){
			var server_type = (E('_xray_basic_type').value == '1');
			
			E("_xray_basic_server").options.length = 0;
			if (server_type){ 
				if (typeof(dbus["xray_server_node_max"]) == "undefined"){
					node_xray = 0;
				}else{
					node_xray = parseInt(dbus["xray_server_node_max"]);
				}
				for ( var i = 0; i < node_xray; i++){
					option_server_list[i] = [ dbus["xray_server_tag_" + ( i + 1)]];
					E("_xray_basic_server").options[i] = new Option(option_server_list[i], i + 1);
				}
				E("_xray_basic_server").options[node_xray] = new Option("新增配置", node_xray + 1);
			}else{
				if (typeof(dbus["xray_sub_node_max"]) == "undefined"){
					node_xray = 0;
				}else{
					node_xray = parseInt(dbus["xray_sub_node_max"]);
				}
				for ( var i = 0; i < node_xray; i++){
					option_server_list[i] = [ dbus["xray_sub_tag_" + ( i + 1)]];
					E("_xray_basic_server").options[i] = new Option(option_server_list[i], i + 1);
				}
			}

			E("_xray_basic_server").value = dbus["xray_basic_server"]
		}

		function tabSelect(obj){
			var tableX = ['app1-tab', 'app2-tab','app3-tab','app4-tab','app5-tab','app6-tab','app7-tab','app8-tab'];
			var boxX = ['boxr1','boxr2','boxr3','boxr4','boxr5','boxr6','boxr7','boxr8'];
			var appX = ['app1','app2','app3','app4','app5','app6','app7','app8'];
			for (var i = 0; i < tableX.length; i++){
				if(obj == appX[i]){
					$('#'+tableX[i]).addClass('active');
					$('.'+boxX[i]).show();
				}else{
					$('#'+tableX[i]).removeClass('active');
					$('.'+boxX[i]).hide();
				}
			}
			if(obj=='app6'){
				elem.display('save-button', false);
				noChange=0;
				setTimeout("get_log();", 200);
			}else if(obj=='app7' || obj=='app8'){
				elem.display('save-button', false);
			}else{
				elem.display('save-button', true);
				noChange=2001;
			}
			if(obj=='fuckapp'){
				elem.display('xray_status_pannel', false);
				elem.display('xray_tabs', false);
				elem.display('xray_basic_tab', false);
				elem.display('xray_wblist_tab', false);
				elem.display('xray_dns_tab', false);
				elem.display('xray_acl_tab', false);
				elem.display('xray_log_tab', false);
				E('save-button').style.display = "";
			}
		}
		function showMsg(Outtype, title, msg){
			$('#'+Outtype).html('<h5>'+title+'</h5>'+msg+'<a class="close"><i class="icon-cancel"></i></a>');
			$('#'+Outtype).show();
		}

		function save(){
			setTimeout("tabSelect('app6')", 500);
			status_time = 999999990;
			get_run_status();
			E("_xray_basic_status_foreign").innerHTML = "国外链接 - 提交中...暂停获取状态！";
			E("_xray_basic_status_china").innerHTML = "国内链接 - 提交中...暂停获取状态！";
			var paras_chk = ["enable", "sbmode", "sniffing", "socks", "http", "ss", "forward", "dns_chromecast", "gfwlist_update", "chnroute_update", "cdn_update", "cron" ];
			var paras_inp = ["xray_acl_default_mode", "xray_dns_plan", "xray_dns_china", "xray_dns_china_user", "xray_dns_foreign_select", "xray_dns_foreign", "xray_dns_foreign_user", "xray_basic_rule_update", "xray_basic_rule_update_day", "xray_basic_rule_update_hr", "xray_basic_watchdog", "xray_basic_watchdog_time", "xray_basic_watchdog_mod", "xray_basic_cron_enablehour", "xray_basic_cron_enableminute", "xray_basic_cron_disablehour", "xray_basic_cron_disableminute", "xray_basic_check_releases", "xray_basic_server", "xray_basic_type", "xray_service_auth", "xray_service_username", "xray_service_passwd", "xray_service_ssmethod", "xray_service_sspasswd" ];
			// collect data from checkbox
			for (var i = 0; i < paras_chk.length; i++) {
				dbus["xray_basic_" + paras_chk[i]] = E('_xray_basic_' + paras_chk[i] ).checked ? '1':'0';
			}
			// data from other element
			for (var i = 0; i < paras_inp.length; i++) {
				if (typeof(E('_' + paras_inp[i] ).value) == "undefined"){
					dbus[paras_inp[i]] = "";
				}else{
					dbus[paras_inp[i]] = E('_' + paras_inp[i]).value;
				}
			}
			// data need base64 encode
			var paras_base64 = ["xray_wan_white_ip", "xray_wan_white_domain", "xray_wan_black_ip", "xray_wan_black_domain", "xray_dnsmasq"];
			for (var i = 0; i < paras_base64.length; i++) {
				if (typeof(E('_' + paras_base64[i] ).value) == "undefined"){
					dbus[paras_base64[i]] = "";
				}else{
					dbus[paras_base64[i]] = Base64.encode(E('_' + paras_base64[i]).value);
				}
			}
			
			//  node status
			var node_type = (E('_xray_basic_type').value == '1');
			var server_id = E('_xray_basic_server').value;
			if (node_type){			
				dbus["xray_server_config_" + server_id] = Base64.encode(E('_xray_basic_config').value);
				var new_tag = (E('_xray_basic_tag').value == "");
				if (!new_tag){
					dbus["xray_server_tag_" + server_id] = E('_xray_basic_tag').value;
					dbus["xray_server_node_max"] = server_id;
				}
			}else{
				dbus["xray_sub_config_" + server_id] = Base64.encode(E('_xray_basic_config').value);
			}

			// collect acl data from acl pannel
			var xray_acl_conf = ["xray_acl_name_", "xray_acl_ip_", "xray_acl_mac_", "xray_acl_mode_" ];
			// mark all acl data for delete first
			for ( var i = 1; i <= dbus["xray_acl_node_max"]; i++){
				for ( var j = 0; j < xray_acl_conf.length; ++j ) {
					dbus[xray_acl_conf[j] + i ] = ""
				}
			}
			var data = xray_acl.getAllData();
			if(data.length > 0){
				for ( var i = 0; i < data.length; ++i ) {
					for ( var j = 1; j < xray_acl_conf.length; ++j ) {
						dbus[xray_acl_conf[0] + (i + 1)] = data[i][0];
						dbus[xray_acl_conf[j] + (i + 1)] = data[i][j];
					}
				}
				dbus["xray_acl_node_max"] = data.length;
			}else{
				dbus["xray_acl_node_max"] = "";
			}
			// now post data
			var id = parseInt(Math.random() * 100000000);
			var postData = {"id": id, "method": "xray_config.sh", "params":[1], "fields": dbus};
			showMsg("msg_warring","正在提交数据！","<b>等待后台运行完毕，请不要刷新本页面！</b>");
			$.ajax({
				url: "/_api/",
				type: "POST",
				async:true,
				cache:false,
				dataType: "json",
				data: JSON.stringify(postData),
				success: function(response){
					if (response.result == id){
						if(E('_xray_basic_enable').checked){
							showMsg("msg_success","提交成功","<b>成功提交数据</b>");
							$('#msg_warring').hide();
							setTimeout("$('#msg_success').hide()", 500);
							x = 4;
							count_down_switch();
						}else{
							// when shut down ss finished, close the log tab
							$('#msg_warring').hide();
							showMsg("msg_success","提交成功","<b>xray成功关闭！</b>");
							setTimeout("$('#msg_success').hide()", 4000);
							setTimeout("tabSelect('fuckapp')", 4000);
						}
					}else{
						$('#msg_warring').hide();
						showMsg("msg_error","提交失败","<b>提交数据失败！错误代码：" + response.result + "</b>");
						setTimeout("window.location.reload()", 500);
					}
				},
				error: function(){
					showMsg("msg_error","失败","<b>当前系统存在异常查看系统日志！</b>");
					status_time = 1;
				}
			});
		}

		function get_log(){
			$.ajax({
				url: '/_temp/xray_log.txt',
				type: 'GET',
				dataType: 'html',
				async: true,
				cache:false,
				success: function(response) {
					var retArea = E("_xray_basic_log");
					if (response.search("XU6J03M6") != -1) {
						retArea.value = response.replace("XU6J03M6", " ");
						retArea.scrollTop = retArea.scrollHeight;
						return true;
					}
					if (_responseLen == response.length) {
						noChange++;
					} else {
						noChange = 0;
					}
					if (noChange > 2000) {
						//tabSelect("app1");
						return false;
					} else {
						setTimeout("get_log();", 100); //100 is radical but smooth!
					}
					retArea.value = response;
					retArea.scrollTop = retArea.scrollHeight;
					_responseLen = response.length;
				},
				error: function() {
					E("_xray_basic_log").value = "获取日志失败！";
				}
			});
		}
		function count_down_switch() {
			if (x == "0") {
				setTimeout("window.location.reload()", 500);
			}
			if (x < 0) {
				return false;
			}
				--x;
			setTimeout("count_down_switch();", 500);
		}
		function manipulate_conf(script, arg){
			var dbus3 = {};
			if(arg == 2 || arg == 4){
				tabSelect("app6");
			}else if(arg == 5){
				dbus3.xray_basic_check_releases = E('_xray_basic_check_releases').value;
				tabSelect("app6");
			}else if(arg == 6){
				status_time = 999999990;
				get_run_status();
				tabSelect("app6");
			}else if(arg == 9){
				// collect acl data from acl pannel
				var xray_server_conf = ["xray_server_tag_", "xray_server_config_"];
				// mark all acl data for delete first
				for ( var i = 1; i <= dbus3["xray_server_node_max"]; i++){
					for ( var j = 0; j < xray_server_conf.length; ++j ) {
						dbus3[xray_server_conf[j] + i ] = ""
					}
				}
				var data = xray_server.getAllData();
				if(data.length > 0){
					for ( var i = 0; i < data.length; ++i ) {
						for ( var j = 1; j < xray_server_conf.length; ++j ) {
							dbus3[xray_server_conf[0] + (i + 1)] = data[i][1];
							dbus3[xray_server_conf[j] + (i + 1)] = Base64.encode(data[i][j+1]);
						}
					}
					dbus3["xray_server_node_max"] = data.length;
				}else{
					dbus3["xray_server_node_max"] = "";
				}
			}else if(arg == 7){
				var paras_chk = ["gfwlist_update", "chnroute_update", "cdn_update"];
				var paras_inp = ["xray_basic_rule_update", "xray_basic_rule_update_day", "xray_basic_rule_update_hr" ];
				// collect data from checkbox
				for (var i = 0; i < paras_chk.length; i++) {
					dbus3["xray_basic_" + paras_chk[i]] = E('_xray_basic_' + paras_chk[i] ).checked ? '1':'0';
				}
				// data from other element
				for (var i = 0; i < paras_inp.length; i++) {
					if (typeof(E('_' + paras_inp[i] ).value) == "undefined"){
						dbus3[paras_inp[i]] = "";
					}else{
						dbus3[paras_inp[i]] = E('_' + paras_inp[i]).value;
					}
				}
				tabSelect("app6");
			}
			var id = parseInt(Math.random() * 100000000);
			var postData = {"id": id, "method": script, "params":[arg], "fields": dbus3 };
			$.ajax({
				type: "POST",
				url: "/_api/",
				async: true,
				cache:false,
				data: JSON.stringify(postData),
				dataType: "json",
				success: function(response){
					if (script == "xray_config.sh"){
						if(arg == 2 || arg == 4 || arg == 6 || arg == 7){
							setTimeout("window.location.reload()", 800);
						}else if (arg == 9){
							if (response.result == id){
								showMsg("msg_success","提交成功","<b>服务器列表保存成功！</b>");
								setTimeout("$('#msg_success').hide()", 4000);								
							}else{
								$('#msg_warring').hide();
								showMsg("msg_error","提交失败","<b>服务器列表保存失败！错误代码：" + response.result + "</b>");
							}
							setTimeout("window.location.reload()", 50);
						}else if (arg == 3){
							var a = document.createElement('A');
							a.href = "/files/xray_conf_backup.sh";
							a.download = 'xray_conf_backup.sh';
							document.body.appendChild(a);
							a.click();
							document.body.removeChild(a);
						}else if (arg == 5){
							setTimeout("tabSelect('app6')", 500);
							setTimeout("window.location.reload()", 800);
						}
					}
				}
			});
		}

		function node_sub(script, arg ,msg){
			var dbus4 = {};
			if(arg == 0 || arg == 1){
				var ask="你确定要删除【" + msg + "】信息？\n删除后不可恢复，确定要删除吗？";
				if(!confirm(ask)){
					return false;
				}
				tabSelect("app6");
			}else if(arg == 2 || arg == 3){
				dbus4.xray_basic_suburl = Base64.encode(E('_xray_basic_suburl').value);
				dbus4.xray_basic_node_update_hr = E('_xray_basic_node_update_hr').value;
				dbus4.xray_basic_node_update_day = E('_xray_basic_node_update_day').value;
				dbus4.xray_basic_node_update = E('_xray_basic_node_update').checked ? '1':'0';
				dbus4.xray_basic_suburl_socks = E('_xray_basic_suburl_socks').checked ? '1':'0';
				tabSelect("app6");
			}else if(arg == 4){
				dbus4.xray_base64_links = E('_xray_base64_links').value;
				tabSelect("app6");
			}
			var id4 = parseInt(Math.random() * 100000000);
			var postData4 = {"id": id4, "method": script, "params":[arg], "fields": dbus4 };
			$.ajax({
				type: "POST",
				url: "/_api/",
				async: true,
				cache:false,
				data: JSON.stringify(postData4),
				dataType: "json",
				success: function(response){
					if (script == "xray_sub.sh"){
						setTimeout("tabSelect('app6')", 500);
						setTimeout("window.location.reload()", 800);
					}
				}
			});
		}

		function restore_conf(){
			var filename = $("#file").val();
			filename = filename.split('\\');
			filename = filename[filename.length-1];
			var filelast = filename.split('.');
			filelast = filelast[filelast.length-1];
			if(filelast !='sh'){
				alert('配置文件格式不正确！');
				return false;
			}
			var formData = new FormData();
			formData.append('xray_conf_backup.sh', $('#file')[0].files[0]);
			$('.popover').html('正在恢复，请稍后……');
			//changeButton(true);
			$.ajax({
				url: '/_upload',
				type: 'POST',
				async: true,
				cache:false,
				data: formData,
				processData: false,
				contentType: false,
				complete:function(res){
					if(res.status==200){
						manipulate_conf('xray_config.sh', 4);
					}
				}
			});
		}

		function version_show() {
			$('#_xray_version').html( '<font color="#1bbf35">xray for openwrt - ' + (dbus["xray_version"]  || "") + '</font>' );
			$.ajax({
				url: 'https://raw.githubusercontent.com/HEXtoDEC/LEDE_XRAY/master/config.json.js',
				type: 'GET',
				dataType: 'json',
				success: function(res) {
					if (typeof(res["version"]) != "undefined" && typeof(dbus["xray_version"]) != "undefined" && res["version"].length > 0 && res["version"] != dbus["xray_version"]) {
						$("#updateBtn").html('升级到：' + res.version);
					}
				}
			});
		}		
	</script>
	<div class="box">
		<div class="heading">
			<span id="_xray_version"></span>
			<a href="#/soft-center.asp" class="btn" style="float:right;border-radius:3px;margin-right:5px;margin-top:0px;">返回</a>
			<a href="https://raw.githubusercontent.com/HEXtoDEC/LEDE_XRAY/master/Changelog.txt" target="_blank" class="btn btn-primary" style="float:right;border-radius:3px;margin-right:5px;margin-top:0px;">更新日志</a>
			<!--<button type="button" id="updateBtn" onclick="check_update()" class="btn btn-primary" style="float:right;border-radius:3px;margin-right:5px;margin-top:0px;">检查更新 <i class="icon-upgrade"></i></button>-->
		</div>
		<div class="content">
			<span class="col" style="line-height:30px;width:700px">
			xray 是一个模块化的代理软件包，它的目标是提供常用的代理软件模块，简化网络代理软件的开发。<br />
			你需要为 xray 安装专用的服务端程序:<a href="https://github.com/xtls/xray-core" target="_blank"> 【点此访问源码项目】 </a><a href="https://github.com/HEXtoDEC/Xray_onekey" target="_blank"> 【点此访问一键服务器安装脚本】 </a>
		</div>
	</div>
	<div class="box" style="margin-top: 0px;">
		<div class="heading">
		</div>
		<div class="content">
			<div id="xray_switch_pannel" class="section" style="margin-top: -20px;"></div>
			<script type="text/javascript">
				$('#xray_switch_pannel').forms([
					{ title: '代理开关', name:'xray_basic_enable',type:'checkbox',  value: dbus.xray_basic_enable == 1 }  // ==1 means default close; !=0 means default open
				]);
			</script>
			<hr />
			<fieldset id="xray_status_pannel">
				<label class="col-sm-3 control-left-label" for="_undefined">代理运行状态</label>
				<div class="col-sm-9">
					<font id="_xray_basic_status_foreign" name="xray_basic_status_foreign" color="#1bbf35">国外链接: waiting...</font>
				</div>
				<div class="col-sm-9" style="margin-top:2px">
					<font id="_xray_basic_status_china" name="xray_basic_status_china" color="#1bbf35">国内链接: waiting...</font>
				</div>
			</fieldset>
		</div>
	</div>
	<ul id="xray_tabs" class="nav nav-tabs">
		<li><a href="javascript:void(0);" onclick="tabSelect('app1');" id="app1-tab" class="active"><i class="icon-system"></i> 帐号设置</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app8');" id="app8-tab"><i class="icon-cloud"></i> 服务器列表</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app4');" id="app4-tab"><i class="icon-lock"></i> 访问控制</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app2');" id="app2-tab"><i class="icon-tools"></i> DNS设定</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app3');" id="app3-tab"><i class="icon-warning"></i> 黑白名单</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app7');" id="app7-tab"><i class="icon-cmd"></i> 规则管理</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app5');" id="app5-tab"><i class="icon-wake"></i> 附加设置</a></li>
		<li><a href="javascript:void(0);" onclick="tabSelect('app6');" id="app6-tab"><i class="icon-hourglass"></i> 查看日志</a></li>	
	</ul>
	<div class="box boxr1" id="xray_basic_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="xray_basic_pannel" class="section"></div>
			<script type="text/javascript">
				$('#xray_basic_pannel').forms([
					{ title: '代理模式', name:'xray_acl_default_mode',type:'select', options:option_acl_mode, value:dbus.xray_acl_default_mode },
					{ title: 'xray服务器类型', name:'xray_basic_type',type:'select',options:[['1', '自建'], ['2', '订阅']], value: dbus.xray_basic_type || '1'},
					{ title: 'xray服务器选择', name:'xray_basic_server',type:'select',options:option_server_list},
					{ title: 'xray进阶设置', multi: [
						{ name:'xray_basic_sbmode',type:'checkbox',value: dbus.xray_basic_sbmode == 1,suffix: '&nbsp;&nbsp;启用配置文件routing项'},
						{ name:'xray_basic_sniffing',type:'checkbox',value: dbus.xray_basic_sniffing == 1,suffix: '&nbsp;&nbsp;启用sniffing流量探测'}
					], help: '本项不了解都不要开启' },	
					{ title: 'xray服务端口', multi: [
						{ name:'xray_basic_socks',type:'checkbox',value: dbus.xray_basic_socks == 1,suffix: '&nbsp;&nbsp;开启socks5代理（端口1281）'},
						{ name:'xray_basic_http',type:'checkbox',value: dbus.xray_basic_http == 1,suffix: '&nbsp;&nbsp;开启http代理（端口1282）'},
						{ name:'xray_basic_ss',type:'checkbox',value: dbus.xray_basic_ss == 1,suffix: '&nbsp;&nbsp;开启ss代理（端口1283）'},
						{ name:'xray_basic_forward',type:'checkbox',value: dbus.xray_basic_forward == 1,suffix: '&nbsp;&nbsp;允许远程连接'}
					], help: '开启一些服务端口给其它客户端本地或远程连接'},	
					{ title: 'xray服务验证方式', name:'xray_service_auth',type:'select', options:option_auth ,value: dbus.xray_service_auth || '1', help: '配置是否启用验证'},	
					{ title: 'xray服务验证信息', multi: [
						{ suffix: '&nbsp;&nbsp;用户名&nbsp;'},
						{ name:'xray_service_username',type:'text',value: dbus.xray_service_username || 'koolshare' ,suffix: '&nbsp;&nbsp;密码&nbsp;'},
						{ name:'xray_service_passwd',type:'password',value: dbus.xray_service_passwd || 'koolshare', peekaboo: 1}
					], help: '设置用户名密码'},	
					{ title: 'xray SS服务配置', multi: [
						{ suffix: '&nbsp;&nbsp;加密方式'},
						{ name:'xray_service_ssmethod',type:'select', options:option_ss_method,value: dbus.xray_service_ssmethod || 'chacha20',suffix: '&nbsp;&nbsp;密码'},
						{ name:'xray_service_sspasswd',type:'password',value: dbus.xray_service_sspasswd || 'koolshare', peekaboo: 1 }
					], help: '设置socks5代理或http代理连接的用户名和密码'},	
					{ title: '新增xray配置标签', name:'xray_basic_tag',type:'text'},
					//{ title: '<b>xray配置文件</b></br></br><font color="#B2B2B2"># 此处填入xray json<br /># 请保证json内outbound的配置正确！</font>', name:'xray_basic_config',type:'textarea', value: do_js_beautify(Base64.decode(dbus.xray_basic_config))||"", style: 'width: 100%; height:450px;' },
					{ title: '<b>xray配置文件</b></br></br><font color="#B2B2B2"># 此处填入xray json<br /># 请保证json内outbound的配置正确！</font>', name:'xray_basic_config',type:'textarea', style: 'width: 100%; height:450px;' },
				]);
				join_node();
			</script>
		</div>
	</div>
	<!-- ------------------ 服务器列表 --------------------- -->
	<div class="box boxr8" id="xray_server_tab" style="margin-top: 0px;">
	<div class="heading">自建服务器列表</div>
		<div class="content">
			<div class="tabContent">
				<table class="line-table" cellspacing=1 id="xray_server_pannel"></table>
			</div>
			<br><hr>
			<button type="button" value="Save" id="save-server-node" onclick="manipulate_conf('xray_config.sh', 9)" class="btn btn-primary">保存服务器列表 <i class="icon-check"></i></button>
		</div>
	</div>
	<div class="box boxr8" id="xray_node_urladd" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content">
			<div id="xray_node_urladd_pannel" class="section"></div>
			<script type="text/javascript">
				$('#xray_node_urladd_pannel').forms([
					{ title: '通过Vless链接添加节点</br></br><font color="#B2B2B2"># 可一次添加多个Vless://链接<br /># 每个链接以空格分隔</font>', name: 'xray_base64_links',type:'textarea', value: dbus.xray_base64_links, style: 'width: 100%; height:100px;' }
				]);
			</script>
			<button type="button" value="Save" id="update-addurl-node" onclick="node_sub('xray_sub.sh', 4)" class="btn btn-primary" style="float:right;margin-right:20px;">添加节点 <i class="icon-check"></i></button>
		</div>
	</div>
	<div class="box boxr8" id="xray_node_subscribe" style="margin-top: 0px;">
		<div class="heading">节点订阅</div>
		<div class="content">
			<div id="xray_node_subscribe_pannel" class="section"></div>
			<script type="text/javascript">
				$('#xray_node_subscribe_pannel').forms([
					{ title: '订阅配置', multi: [
						{ suffix: ' 开启定时更新' },
						{ name: 'xray_basic_node_update',type: 'checkbox',value: dbus.xray_basic_node_update == 1 ,suffix: ' &nbsp;&nbsp;' },
						{ name: 'xray_basic_node_update_day',type: 'select', options:option_day_time, value: dbus.xray_basic_node_update_day || '7' ,suffix: ' &nbsp;' },
						{ name: 'xray_basic_node_update_hr',type: 'select', options:option_time_hour, value: dbus.xray_basic_node_update_hr || '3' ,suffix: ' &nbsp;&nbsp;通过xray代理更新节点信息' },
						{ name: 'xray_basic_suburl_socks',type: 'checkbox',value: dbus.xray_basic_suburl_socks == 1 },
						{ suffix: '<button id="_remove_sub_node" onclick="node_sub(\'xray_sub.sh\', 2 ,\'订阅节点\');" class="btn btn-success">删除订阅节点 <i class="icon-cancel"></i></button>' },
						{ suffix: '<button id="_remove_all_node" onclick="node_sub(\'xray_sub.sh\', 1 ,\'所有节点\');" class="btn btn-success">清空所有节点 <i class="icon-disable"></i></button>' },
					]},
					{ title: '订阅地址', name: 'xray_basic_suburl',type:'text',size: 100, value: Base64.decode(dbus.xray_basic_suburl) }
				]);
			</script>
			<!--<button type="button" value="Save" id="dele-subscribe-node" onclick="delete_online_node()" class="btn" style="float:right;">删除订阅节点 <i class="icon-cancel"></i></button>-->
			<button type="button" value="Save" id="update-subscribe-node" onclick="node_sub('xray_sub.sh', 3)" class="btn btn-primary" style="float:right;margin-right:20px;">保存设置并更新订阅 <i class="icon-check"></i></button>
		</div>
	</div>
	<div class="box boxr2" id="xray_dns_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="xray_dns_pannel" class="section"></div>
			<script type="text/javascript">
				$('#xray_dns_pannel').forms([
					{ title: 'DNS解析偏好', name:'xray_dns_plan',type:'select',options:[['1', '国内优先'], ['2', '国外优先']], value: dbus.xray_dns_plan || "2", suffix: '<lable id="_xray_dns_plan_txt"></lable>'},
					{ title: 'chromecast支持 (接管局域网DNS解析)',  name:'xray_basic_dns_chromecast',type:'checkbox', value: dbus.xray_basic_dns_chromecast != 0, suffix: '<lable>此处强烈建议开启！</lable>' },
					{ title: '选择国内DNS', multi: [
						{ name: 'xray_dns_china',type:'select', options:option_dns_china, value: dbus.xray_dns_china || "1", suffix: ' &nbsp;&nbsp;' },
						{ name: 'xray_dns_china_user', type: 'text', value: dbus.xray_dns_china_user }
					]},
					// dns foreign pcap
					{ title: '选择国外DNS', multi: [
						{ name: 'xray_dns_foreign_select',type: 'select', options:option_dns_foreign, value: dbus.xray_dns_dns_foreign || "1", suffix: ' &nbsp;&nbsp;' },
						{ name: 'xray_dns_foreign',type: 'select', options:option_xray_dns_foreign, value: dbus.xray_dns_foreign || "2", suffix: ' &nbsp;&nbsp;' },
						{ name: 'xray_dns_foreign_user', type: 'text', value: dbus.xray_dns_foreign_user || "8.8.8.8:53" },
						{ suffix: '<lable>默认使用 xray 内置的DNS功能解析国外域名。</lable>' }
					]},
					{ title: '<b>自定义dnsmasq</b></br></br><font color="#B2B2B2">一行一个，错误的格式会导致dnsmasq不能启动，格式：</br>address=/koolshare.cn/2.2.2.2</br>bogus-nxdomain=220.250.64.18</br>conf-file=/koolshare/mydnsmasq.conf</font>', name: 'xray_dnsmasq', type: 'textarea', value: Base64.decode(dbus.xray_dnsmasq)||"", style: 'width: 100%; height:150px;' }
				]);
			</script>
		</div>
	</div>
	<div class="box boxr3" id="xray_wblist_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="xray_wblist_pannel" class="section"></div>
			<script type="text/javascript">
				$('#xray_wblist_pannel').forms([
					{ title: '<b>IP/CIDR白名单</b></br></br><font color="#B2B2B2">不需要加速的外网ip/cidr地址，一行一个，例如：</br>2.2.2.2</br>3.3.0.0/16</font>', name: 'xray_wan_white_ip', type: 'textarea', value: Base64.decode(dbus.xray_wan_white_ip)||"", style: 'width: 100%; height:150px;' },
					{ title: '<b>域名白名单</b></br></br><font color="#B2B2B2">不需要加速的域名，例如：</br>google.com</br>facebook.com</font>', name: 'xray_wan_white_domain', type: 'textarea', value: Base64.decode(dbus.xray_wan_white_domain)||"", style: 'width: 100%; height:150px;' },
					{ title: '<b>IP/CIDR黑名单</b></br></br><font color="#B2B2B2">需要加速的外网ip/cidr地址，一行一个，例如：</br>4.4.4.4</br>5.0.0.0/8</font>', name: 'xray_wan_black_ip', type: 'textarea', value: Base64.decode(dbus.xray_wan_black_ip)||"", style: 'width: 100%; height:150px;' },
					{ title: '<b>域名黑名单</b></br></br><font color="#B2B2B2">需要加速的域名,例如：</br>baidu.com</br>koolshare.cn</font>', name: 'xray_wan_black_domain', type: 'textarea', value: Base64.decode(dbus.xray_wan_black_domain)||"", style: 'width: 100%; height:150px;' }
				]);
			</script>
		</div>
	</div>	
	<div class="box boxr4" id="xray_acl_tab" style="margin-top: 0px;">
		<div class="content">
			<div class="tabContent">
				<table class="line-table" cellspacing=1 id="xray_acl_pannel"></table>
			</div>
			<br><hr>
		</div>
	</div>
	<!-- ------------------ 规则管理 --------------------- -->
	<div class="box boxr7" id="ss_rule_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="ss_rule_pannel" class="section"></div>
			<script type="text/javascript">
				$('#ss_rule_pannel').forms([
					{ title: 'gfwlist域名数量', rid:'gfw_number_1', text:'<a id="gfw_number" href="https://raw.githubusercontent.com/HEXtoDEC/LEDE_XRAY/main/rules/gfwlist.conf" target="_blank"></a>'},
					{ title: '大陆白名单IP段数量', rid:'chn_number_1', text:'<a id="chn_number" href="https://raw.githubusercontent.com/HEXtoDEC/LEDE_XRAY/main/rules/chnroute.txt" target="_blank"></a>'},
					{ title: '国内域名数量（cdn名单）', rid:'cdn_number_1', text:'<a id="cdn_number" href="https://raw.githubusercontent.com/HEXtoDEC/LEDE_XRAY/main/rules/cdn.txt" target="_blank"></a>'},
					{ title: '规则自动更新', multi: [
						{ name: 'xray_basic_rule_update',type: 'select', options:[['0', '禁用'], ['1', '开启']], value: dbus.xray_basic_rule_update || "1", suffix: ' &nbsp;&nbsp;' },
						{ name: 'xray_basic_rule_update_day', type: 'select', options:option_day_time, value: dbus.xray_basic_rule_update_day || "7",suffix: ' &nbsp;&nbsp;' },
						{ name: 'xray_basic_rule_update_hr', type: 'select', options:option_time_hour, value: dbus.xray_basic_rule_update_hr || "3",suffix: ' &nbsp;&nbsp;' },
						{ name: 'xray_basic_gfwlist_update',type:'checkbox',value: dbus.xray_basic_gfwlist_update != 0, suffix: '<lable id="_xray_basic_gfwlist_update_txt">gfwlist</lable>&nbsp;&nbsp;' },
						{ name: 'xray_basic_chnroute_update',type:'checkbox',value: dbus.xray_basic_chnroute_update != 0, suffix: '<lable id="_xray_basic_chnroute_update_txt">chnroute</lable>&nbsp;&nbsp;' },
						{ name: 'xray_basic_cdn_update',type:'checkbox',value: dbus.xray_basic_cdn_update != 0, suffix: '<lable id="_xray_basic_cdn_update_txt">cdn_list</lable>&nbsp;&nbsp;' },
						{ suffix: '<button id="_update_rules_now" onclick="manipulate_conf(\'xray_config.sh\', 6);" class="btn btn-success">手动更新 <i class="icon-cloud"></i></button>' }
					]}
				]);
				$('#gfw_number').html(dbus.xray_basic_gfw_status || "未初始化");
				$('#chn_number').html(dbus.xray_basic_chn_status || "未初始化");
				$('#cdn_number').html(dbus.xray_basic_cdn_status || "未初始化");
			</script>
		</div>
	</div>
	<button type="button" value="Save" id="save-subscribe-node" onclick="manipulate_conf('xray_config.sh', 7)" class="btn btn-primary boxr7">保存本页设置 <i class="icon-check"></i></button>
	<div class="box boxr5" id="xray_addon_tab" style="margin-top: 0px;">
		<div class="heading"></div>
		<div class="content" style="margin-top: -20px;">
			<div id="xray_addon_pannel" class="section"></div>
			<script type="text/javascript">
				$('#xray_addon_pannel').forms([
					{ title: 'xray 自动守护', multi: [
						{ name: 'xray_basic_watchdog',type: 'select', options:[['0', '禁用'], ['1', '开启']], value: dbus.xray_basic_watchdog || "1", suffix: ' &nbsp;&nbsp;检测间隔：' },
						{ name: 'xray_basic_watchdog_time', type: 'select', options:option_time_watch, value: dbus.xray_basic_watchdog_time || "1",suffix: ' &nbsp;&nbsp;掉线重连方案：' },
						{ name: 'xray_basic_watchdog_mod', type: 'select', options:option_time_mod, value: dbus.xray_basic_watchdog_mod || "1",suffix: ' &nbsp;&nbsp;' },
					]},
					{ title: '定时自动开关', name:'xray_basic_cron',type:'checkbox',  value: dbus.xray_basic_cron == 1 },
					{ title: '定时开启', multi: [
						{ name: 'xray_basic_cron_enablehour',type: 'select', options:option_time_hour, value: dbus.xray_basic_cron_enablehour || '8' ,suffix: ' 时' },
						{ name: 'xray_basic_cron_enableminute',type: 'select', options:option_time_minute, value: dbus.xray_basic_cron_enableminute || '0' ,suffix: ' 分' },
					]},
					{ title: '定时关闭', multi: [
						{ name: 'xray_basic_cron_disablehour',type: 'select', options:option_time_hour, value: dbus.xray_basic_cron_disablehour || '2' ,suffix: ' 时' },
						{ name: 'xray_basic_cron_disableminute',type: 'select', options:option_time_minute, value: dbus.xray_basic_cron_disableminute || '30' ,suffix: ' 分' },
					]},
					{ title: 'xray 数据操作', suffix: '<button onclick="manipulate_conf(\'xray_config.sh\', 2);" class="btn btn-success">清除所有 xray 数据</button>&nbsp;&nbsp;&nbsp;&nbsp;<button onclick="manipulate_conf(\'xray_config.sh\', 3);" class="btn btn-download">备份所有 xray 数据</button>' },
					{ title: 'xray 数据恢复', suffix: '<input type="file" id="file" size="50">&nbsp;&nbsp;<button id="upload1" type="button"  onclick="restore_conf();" class="btn btn-danger">上传并恢复 <i class="icon-cloud"></i></button>' },
					{ title: 'xray 当前版本', suffix: '<a id="xray_version" href="https://github.com/xtls/xray-core/releases" target="_blank"></a>'},
					{ title: 'xray 版本升级', multi: [
						{ name:'xray_basic_check_releases',type:'select', options:[['0', '升级到最新版（包括测试版）'], ['1', '仅升级到正式版']], value: dbus.xray_basic_check_releases || "1" ,suffix: '  &nbsp;&nbsp;'},
						{ suffix: '<button onclick="manipulate_conf(\'xray_config.sh\', 5);" class="btn btn-download">一键升级xray 版本</button>' }
					]}
				]);
				$('#xray_version').html(dbus.xray_basic_version || "未初始化");
			</script>
		</div>
	</div>
	<div class="box boxr6" id="xray_log_tab" style="margin-top: 0px;">
		<div id="xray_log_pannel" class="content">
			<div class="section content">
				<script type="text/javascript">
					y = Math.floor(docu.getViewSize().height * 0.45);
					s = 'height:' + ((y > 300) ? y : 300) + 'px;display:block';
					$('#xray_log_pannel').append('<textarea class="as-script" name="_xray_basic_log" id="_xray_basic_log" readonly wrap="off" style="max-width:100%; min-width: 100%; margin: 0; ' + s + '" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false"></textarea>');
				</script>
			</div>
		</div>
	</div>
	<div id="msg_warring" class="alert alert-warning icon" style="display:none;"></div>
	<div id="msg_success" class="alert alert-success icon" style="display:none;"></div>
	<div id="msg_error" class="alert alert-error icon" style="display:none;"></div>
	<button type="button" value="Save" id="save-button" onclick="save()" class="btn btn-primary">提交 <i class="icon-check"></i></button>
	<script type="text/javascript">init_xray();</script>
</content>
