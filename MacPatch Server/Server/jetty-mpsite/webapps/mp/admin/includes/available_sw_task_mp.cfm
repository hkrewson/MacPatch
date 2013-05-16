<script type="text/Javascript">
	function load(url,id)
	{
		window.open(url,'_self') ;
	}
</script>
<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			$("#list").jqGrid(
			{
				url:'./includes/available_sw_task_mp.cfc?method=getMPSoftwareTasks', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','TaskID', 'Name','', 'Active', 'Task Type', 'Valid From', 'Valid To', 'Create Date' , 'Modify Date'],
				colModel :[
				  {name:'rid',index:'rid', width:30, align:"center", sortable:false, resizable:false},
				  {name:'tuuid',index:'tuuid', width:30, align:"center", hidden: true},
				  {name:'name',index:'name', width:150, align:"left"},
				  {name:'primary_suuid',index:'primary_suuid', width:30, align:"center", hidden: true},
				  {name:'active', index:'active', width:50, align:"left"},
				  {name:'sw_task_type', index:'sw_task_type', width:80, align:"left"},
				  {name:'sw_start_datetime', index:'sw_start_datetime', width:120, align:"left"},
				  {name:'sw_end_datetime', index:'sw_end_datetime', width:120, align:"left"},
				  {name:'cdate', index:'cdate', width:120, align:"left"},
				  {name:'mdate', index:'mdate', width:120, align:"left"}
				],
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "mdate", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Software Distribution Tasks', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"includes/available_sw_task_mp.cfc?method=addEditMPSoftwareTask",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){
					var ids = jQuery("#list").getDataIDs();
					for(var i=0;i<ids.length;i++){
						var cl = ids[i];
						var xl = jQuery("#list").getCell(ids[i],'tuuid'); // get tuuid
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('./index.cfm?adm_sw_task_edit="+xl+"'); src='./_assets/images/jqGrid/edit_16.png'>";
						<cfelse>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('./index.cfm?adm_sw_task_edit="+xl+"'); src='./_assets/images/jqGrid/info_16.png'>";
						</cfif>
						jQuery("#list").setRowData(ids[i],{rid:edit})
					}
				},
				onSelectRow: function(id){
					/* This section of code fixes the highlight issues, with altRows */
					if(id && id!==lastsel){
						var xyz = $("#list").getDataIDs().indexOf(lastsel);
						if (xyz%2 != 0)
						{
						  $('#'+lastsel).addClass('ui-priority-secondary');
						}

					  $('#list').jqGrid('restoreRow',lastsel);
					  lastsel=id;
					}
					$('#'+id).removeClass('ui-priority-secondary');
				},
				jsonReader: {
					total: "total",
					page: "page",
					records:"records",
					root: "rows",
					userdata: "userdata",
					cell: "",
					id: "0"
					}
				}
			);
			<cfif session.IsAdmin IS true>
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:true})
			.navButtonAdd('#pager',{
			   caption:"",
			   buttonicon:"ui-icon-plus",
			   title:"Add New Patch",
			   onClickButton: function(){
				 load('./index.cfm?adm_sw_task_new');
			   }
			})
			/*
			.navButtonAdd('#pager',{
			   caption:"",
			   buttonicon:"ui-icon-copy",
			   title:"Duplicate Patch",
			   onClickButton: function(){
				 load("./index.cfm?adm_sw_task_dup="+ lastsel);
			   },
			   position:"last"
			})*/;
			<cfelse>
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false});
			</cfif>
		}
	);
</script>
<div align="center">
<table id="list" cellpadding="0" cellspacing="0"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="dialog" title="Detailed Task Information" style="text-align:left;" class="ui-dialog-titlebar"></div>