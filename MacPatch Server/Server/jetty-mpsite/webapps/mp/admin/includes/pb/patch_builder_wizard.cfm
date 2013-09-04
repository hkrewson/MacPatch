<cfset isReq="Yes">

<style type="text/css">
.example {
	padding: 20;
}
.alignleftH2 {
	float: left;
	vertical-align:text-top;
	font-size: 16px;
	font-weight: bold;
	padding-bottom: 6px;
}
.alignleft {
	float: left;
	vertical-align:text-top;
}
.alignright {
	float: right;
	vertical-align:text-top;
}
</style>


<!--- Smart Wizard Setup --->
<script type="text/javascript">
    $().ready(function() {
        $('.wiz-container').smartWizard();
        // The actual autocomplete function, you can hook autocomplete up on a field by field basis.
		$("#suggest").autocomplete('./includes/pb/autofill/asproxy.cfm', {
			minChars: 1, // The absolute chars we want is at least 1 character.
			width: 300,  // The width of the auto complete display
			formatItem: function(row){
				return row[0]; // Formatting of the autocomplete dropdown.
			}
		});
    }); 
</script>

<!--- Picker --->
<SCRIPT LANGUAGE="JavaScript">
    function showList(frmEleName) {
      sList = window.open("./includes/pb/patch_picker.cfm?INName="+frmEleName, "list", "width=400,height=500");
    }
    
    function showHelp() {
      sList = window.open("includes/pb/patch_builder_help.cfm", "Help", "width=800,height=500");
    }
    
    function remLink() {
      if (window.sList && window.sList.open && !window.sList.closed)
        window.sList.opener = null;
    }
</SCRIPT>

<!--- Add & Remove Input Form Fields --->
<script type="text/javascript">
    function addFormField(frmFieldName, pid, divid) {
        var id = document.getElementById(pid).value;
        id = (id - 1) + 2;
        document.getElementById(pid).value = id;
        var rmRef = "<img src='./_assets/images/cancel.png' style='vertical-align:middle;' height='14' width='14' onClick='removeFormField(\"#row" + frmFieldName + id +"\")\; return false\;'>";
        $("#"+divid).append("<p id='row" + frmFieldName + id +"' style='margin-top:4px;'>"+rmRef+"&nbsp;<img src='./_assets/images/info.png' style='vertical-align:middle;' height='14' width='14' onClick=\"showList('"+frmFieldName+":"+id+"')\;\">&nbsp;<input type='text' size='50' name='pName" + frmFieldName + ":" + id + "' id='pName" + frmFieldName + ":" + id +"' disabled><input type='hidden' size='20' name='" + frmFieldName + "_" + id + "' id='"+frmFieldName + id +"'>&nbsp;<input type='text' name='"+frmFieldName+"Order_"+id+"' value='"+id+"' size='4'>(Order)&nbsp;<p>");
    }

    function removeFormField(id) {
        $(id).remove();
        //document.getElementById(id).remove();
    }
</script>

<script type="text/javascript">
    function addFormCriteriaField(frmFieldName, pid, divid) {
        var id = document.getElementById(pid).value;
        id = (id - 1) + 2;
        document.getElementById(pid).value = id;

        var rmRef = "<a href='#' onClick='removeFormField(\"#row" + frmFieldName + id +"\"); return false;'><img src='./_assets/images/cancel.png' style='vertical-align:top;margin-top:2px;' height='14' width='14'></a>";
        var sel = "<select name='type_"+ id + "' id='"+frmFieldName + id +"' size='1' style='vertical-align:top\;'><option>BundleID</option><option>File</option><option>Script</option></select>";
        $("#"+divid).append("<p id='row" + frmFieldName + id +"' style='margin-top:4px;'>&nbsp;"+sel+"&nbsp;<textarea name='" + frmFieldName + "_" + id + "' class='example' id='"+frmFieldName + id +"' cols=\"100\" />&nbsp;<input type='text' name='"+frmFieldName+"Order_"+id+"' value='"+id+"' size='4' style='vertical-align:top\;'><span style='vertical-align:top\;'>(Order)</span>&nbsp;"+rmRef+"</p>");
        //<p id='row" + id + "'>
    }

    function removeFormField(id) {
        $(id).remove();
        //document.getElementById(id).remove();
    }
</script>

<cfform name="stepIt" method="post" action="./includes/pb/post.cfm" enctype="multipart/form-data">
<div id="smartwizard" class="wiz-container">
    <ul id="wizard-anchor">
        <li><a href="#wizard-1"><h2>Step 1</h2>
      <small>Patch Information</small></a></li>
        <li><a href="#wizard-2"><h2>Step 2</h2>
      <small>Patch Criteria</small></a></li>
        <li><a href="#wizard-3"><h2>Step 3</h2>
      <small>Patch Package</small></a></li>
        <li><a href="#wizard-4"><h2>Step 4</h2>
      <small>Additional Patches &amp; Save</small></a></li>
    </ul>
	<div id="wizard-body" class="wiz-body">
  			<div id="wizard-1" >
  			   <div class="wiz-content">
                <h2>Patch Information</h2>
                <p>
                <div id="container">
                    <div id="row">
                        <div id="left">
                            Patch Name
                        </div>
                        <div id="center">
                            <cfinput type="text" name="patch_name" SIZE="50" required="#isReq#" message="Error [patch name]: A patch name is required.">
                        </div> 
                        <div id="right">
                        	(e.g. "FireFox") 
                        </div> 
                    </div>
                    <div id="row">
                        <div id="left">
                            Patch Version
                        </div>
                        <div id="center">
                            <cfinput type="text" name="patch_ver" SIZE="50" required="#isReq#" message="Error [patch version]: A patch version is required.">
                        </div>
                        <div id="right">
                        	(e.g. "3.5.4") 
                        </div> 
                    </div>
					<div id="row">
		            	<div id="left"> Patch Vendor </div>
		              	<div id="center">
		                	<cfinput type="text" name="patch_vendor" SIZE="50">
		              	</div>
		              	<div id="right">&nbsp;</div>
		            </div>
                    <div id="row">
                        <div id="left">
                            Patch Description
                        </div>
                        <div id="center">
                            <textarea name="description" cols="48" rows="9"></textarea>
                        </div>
                        <div id="right">&nbsp;</div>  
                    </div>
                    <div id="row">
                        <div id="left">
                            Patch Info URL 
                        </div>
                        <div id="center">
                            <cfinput type="text" name="description_url" SIZE="50">
                        </div>
                        <div id="right">&nbsp;</div> 
                    </div>
                    <div id="row">
                        <div id="left">
                            Patch Severity
                        </div>
                        <div id="center">
                            <cfselect name="patch_severity" size="1" required="yes">
                                <option>High</option>
                                <option>Medium</option>
                                <option>Low</option>
                                <option>Unknown</option>
                            </cfselect>
                        </div>    
                        <div id="right">&nbsp;</div>  
                    </div>
                    <div id="row">
                        <div id="left">
                            Patch State
                        </div>
                        <div id="center">
                            <cfselect name="patch_state" size="1">
                                <option>Create</option>
                                <option>QA</option>
                                <option>Production</option>
                            </cfselect>
                        </div>  
                        <div id="right">&nbsp;</div>    
                    </div>
                    <div id="row">
                        <div id="left">
                            CVE ID
                        </div>
                        <div id="center">
                            <cfinput type="text" name="cve_id" SIZE="50">
                        </div>
                        <div id="right">&nbsp;</div>  
                    </div>
                </div>        
            </div> 
            </p>       
            <div class="wiz-nav">
              <input class="next btn" id="next" type="button" value="Next >" />
            </div>          
        </div>
  			<div id="wizard-2">
  			   <div class="wiz-content">
				<div id="textbox">
                <p class="alignleftH2">Patch Criteria</p><p class="alignright">
					<a href="#" onClick="showHelp();"><img src="./_assets/images/icons/help.png" /></a>
                </div>
				<p>
                	<div id="container">
                       <div id="row">
                            <div id="left">
                                OS Type
                            </div>
                            <div id="center">
                                <cfselect name="req_os_type" size="1">
                                    <option>Mac OS X</option>
                                    <option>Mac OS X Server</option>
                                    <option selected>Mac OS X, Mac OS X Server</option>
                                </cfselect>
                            </div>
                            <div id="right">
                                (e.g. "Mac OS X, Mac OS X Server") 
                            </div>  
                        </div>
                        <div id="row">
                            <div id="left">
                                OS Version
                            </div>
                            <div id="center">
                                <cfinput type="text" name="req_os_ver" SIZE="50" required="#isReq#" message="Error [Required OS Version]: A OS version is required." value="*">
                            </div>
                            <div id="right">
                                (e.g. "10.4.*,10.5.*") 
                        	</div> 
                    	</div>
						<div id="row">
			              <div id="left"> Architecture Type </div>
			              <div id="center">
			                <cfselect name="req_os_arch" size="1">
			                <option>PPC</option>
			                <option>X86</option>
			                <option selected>PPC, X86</option>
			                </cfselect>
			              </div>
			              <div id="right">(e.g. "PPC, X86"; Universal)</div>
			            </div>
                    </div>
                    <div id="container">
					<h3><a href="#" onClick="addFormCriteriaField('reqPatchCriteria','reqid','divTxtReq'); return false;"><img src="./_assets/images/process_add_16.png" />Add Criteria</a></h3>
                    <input type="hidden" id="reqid" value="0">
                    <div id="divTxtReq"></div>
                    <br />
                    </div>
                </p>
            </div>  
            <div class="wiz-nav">
              <input class="back btn" id="back" type="button" value="< Back" />
              <input class="next btn" id="next" type="button" value="Next >" />            
            </div>                        
        </div>
  			<div id="wizard-3">
  			   <div class="wiz-content">
                <h2>Patch Package</h2>	
                <p>
                	<div id="container">
                        <div id="row">
                            <div id="left">
                                Patch Group ID
                            </div>
                            <div id="center">
                                <input type="text" id="suggest" name="bundle_id" SIZE="60" required="#isReq#" message="Error [Patch Group ID]: A patch group id is required." value="">
                            </div>
                            <div id="right">
                                (e.g. org.mozilla.firefox)
                            </div>  
                    	</div>
                        <div id="row">
                            <div id="left">
                                PreInstall Script
                            </div>
                            <div id="center">
                                <textarea name="pkg_preinstall" cols="60" rows="7"></textarea>
                            </div>
                            <div id="right">
                                Note: The return code of "0" is True.
                            </div>  
                    	</div>
                        <div id="row">
                            <div id="left">
                                PostInstall Script
                            </div>
                            <div id="center">
                                <textarea name="pkg_postinstall" cols="60" rows="7"></textarea>
                            </div>
                            <div id="right">
                                Note: The return code of "0" is True.
                            </div>   
                        </div>
                        <div id="row">
                            <div id="left">
                                Patch Package
                            </div>
                            <div id="center">
                                <cfinput type="file" name="mainPatchFile" required="#isReq#" message="Error [Patch File]: A patch package name is required.">
                            </div>
                            <div id="right">(Note: The file must be a zipped pkg or mpkg)</div>  
                    	</div>
						<div id="row">
                            <div id="left">
								Installer Env Variables
                            </div>
                            <div id="center">
                                <input type="text" id="env_var" name="pkg_env_var" SIZE="60" value="">
                            </div>
                            <div id="right">(Example: ATTR=VALUE,ATTR=VALUE)</div>  
                    	</div>
						<div id="row">
			            	<div id="left"> Patch Install Weight </div>
			            	<div id="center" style="color:black;">
			                	<input name="patchInstallWeight" id="patchInstallWeight" type="range" min="0" max="100" step="1" title="" value="50" onchange="document.getElementById('patchInstallWeight-out').innerHTML = this.value" />
								<span id="patchInstallWeight-out">50</span>
			              	</div>
							<div id="right">Sets a patch install weight order.<br>Lower = Earlier</div>
			            </div>
                        <div id="row">
                            <div id="left">
                                Patch Requires Reboot
                            </div>
                            <div id="center">
                                <cfselect name="patch_reboot" size="1">
                                    <option>Yes</option>
                                    <option selected>No</option>
                                </cfselect>
                            </div>  
                            <div id="right">&nbsp;</div>    
                        </div>
                    </div>
                </p>   
            </div>           
            <div class="wiz-nav">
              <input class="back btn" id="back" type="button" value="< Back" />
              <input class="next btn" id="next" type="button" value="Next >" />            
            </div>             
        </div>
		<div id="wizard-4">
            <div class="wiz-content">
                <h2>Additional Patches &amp; Finish</h2>	
                
                <label>Pre-Requisite Package(s)</label>
                <h3><a href="#" onClick="addFormField('prePatchPKG','preid','divTxtPre'); return false;"><img src="./_assets/images/pkg_add.png" />Add</a></h3>
                <input type="hidden" id="preid" value="0">
                <div id="divTxtPre"></div>
                <br />
                <label>Post-Requisite Package(s)</label>
                <h3><a href="#" onClick="addFormField('postPatchPKG','postid','divTxtPost'); return false;"><img src="./_assets/images/pkg_add.png" />Add</a></h3>
                <input type="hidden" id="postid" value="0">
                <div id="divTxtPost"></div>
                </div>            
                    <div class="wiz-nav">
                      <input type="hidden" name="active" value="0" SIZE="50">
                      
                      <input class="back btn" id="back" type="button" value="< Back" />
                      <input class="btn" id="next" type="submit" value="Save" />
                    </div>             
                </div>
            </div>
	</div>	
</p>          
</cfform>
