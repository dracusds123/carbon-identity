<%--
  ~ Copyright (c) 2015, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~ WSO2 Inc. licenses this file to you under the Apache License,
  ~ Version 2.0 (the "License"); you may not use this file except
  ~ in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied.  See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
  --%>

<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="carbon" uri="http://wso2.org/projects/carbon/taglibs/carbontags.jar" %>
<%@ page import="org.apache.axis2.context.ConfigurationContext" %>
<%@ page import="org.wso2.carbon.CarbonConstants" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.stub.bean.BPSProfileDTO" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.stub.bean.TemplateDTO" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.stub.bean.TemplateImplDTO" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.stub.bean.TemplateParameterDef" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.ui.WorkflowAdminServiceClient" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.ui.WorkflowUIConstants" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIMessage" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIUtil" %>
<%@ page import="org.wso2.carbon.ui.util.CharacterEncoder" %>
<%@ page import="org.wso2.carbon.utils.ServerConstants" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.stub.bean.TemplateBean" %>

<%
    String requestPath = "list-workflows";
    if(request.getParameter("path") != null && !request.getParameter("path").isEmpty()){
        requestPath = request.getParameter("path")  ;
    }

    String workflowName = CharacterEncoder.getSafeText(request.getParameter(WorkflowUIConstants.PARAM_WORKFLOW_NAME));
    String template = CharacterEncoder.getSafeText(request.getParameter(WorkflowUIConstants.PARAM_WORKFLOW_TEMPLATE));
    String description =
            CharacterEncoder.getSafeText(request.getParameter(WorkflowUIConstants.PARAM_WORKFLOW_DESCRIPTION));
    Map<String, String> templateParams = new HashMap<String, String>();

    TemplateBean[] templateList = null;
    String templateImpl = null;
    if (session.getAttribute(WorkflowUIConstants.ATTRIB_WORKFLOW_WIZARD) != null &&
            session.getAttribute(WorkflowUIConstants.ATTRIB_WORKFLOW_WIZARD) instanceof Map) {
        Map<String, String> attribMap =
                (Map<String, String>) session.getAttribute(WorkflowUIConstants.ATTRIB_WORKFLOW_WIZARD);
        //setting params from previous page
        if (workflowName == null) {
            workflowName = attribMap.get(WorkflowUIConstants.PARAM_WORKFLOW_NAME);
        } else {
            attribMap.put(WorkflowUIConstants.PARAM_WORKFLOW_NAME, workflowName);
        }

        if (template == null) {
            template = attribMap.get(WorkflowUIConstants.PARAM_WORKFLOW_TEMPLATE);
        } else {
            attribMap.put(WorkflowUIConstants.PARAM_WORKFLOW_TEMPLATE, template);
        }

        if (description == null) {
            description = attribMap.get(WorkflowUIConstants.PARAM_WORKFLOW_DESCRIPTION);
        } else {
            attribMap.put(WorkflowUIConstants.PARAM_WORKFLOW_DESCRIPTION, description);
        }

        for (Map.Entry<String, String> entry : attribMap.entrySet()) {
            if (entry.getKey().startsWith("p-")) {
                templateParams.put(entry.getKey(), entry.getValue());
            }
        }
        templateImpl = attribMap.get(WorkflowUIConstants.PARAM_TEMPLATE_IMPL);
        session.setAttribute(WorkflowUIConstants.ATTRIB_WORKFLOW_WIZARD, attribMap);
    }

    WorkflowAdminServiceClient client;
    String bundle = "org.wso2.carbon.identity.workflow.mgt.ui.i18n.Resources";
    ResourceBundle resourceBundle = ResourceBundle.getBundle(bundle, request.getLocale());
    String forwardTo = null;
    TemplateDTO templateDTO = null;
    BPSProfileDTO[] bpsProfiles = new BPSProfileDTO[0];

    try {
        String cookie = (String) session.getAttribute(ServerConstants.ADMIN_SERVICE_COOKIE);
        String backendServerURL = CarbonUIUtil.getServerURL(config.getServletContext(), session);
        ConfigurationContext configContext =
                (ConfigurationContext) config.getServletContext()
                        .getAttribute(CarbonConstants.CONFIGURATION_CONTEXT);
        client = new WorkflowAdminServiceClient(cookie, backendServerURL, configContext);

        templateList = client.listTemplates();
        if (templateList == null) {
            templateList = new TemplateBean[0];
        }

        if(template != null) {
            templateDTO = client.getTemplate(template);
            bpsProfiles = client.listBPSProfiles();
        }

    } catch (Exception e) {
        String message = resourceBundle.getString("workflow.error.when.initiating.service.client");
        CarbonUIMessage.sendCarbonUIMessage(message, CarbonUIMessage.ERROR, request);
        forwardTo = "../admin/error.jsp";
    }
%>
<%
    if (forwardTo != null) {
%>
<script type="text/javascript">
    function forward() {
        location.href = "<%=forwardTo%>";
    }
</script>

<script type="text/javascript">
    forward();
</script>
<%
        return;
    }
%>

<fmt:bundle basename="org.wso2.carbon.identity.workflow.mgt.ui.i18n.Resources">
    <carbon:breadcrumb
            label="workflow.template"
            resourceBundle="org.wso2.carbon.identity.workflow.mgt.ui.i18n.Resources"
            topPage="false"
            request="<%=request%>"/>

    <script type="text/javascript" src="../carbon/admin/js/breadcrumbs.js"></script>
    <script type="text/javascript" src="../carbon/admin/js/cookies.js"></script>
    <script type="text/javascript" src="../carbon/admin/js/main.js"></script>
    <script type="text/javascript">
        function goBack() {
            location.href =
                    "add-workflow.jsp?<%=WorkflowUIConstants.PARAM_ACTION%>=<%=WorkflowUIConstants.ACTION_VALUE_BACK%>";
        }

        function doCancel() {
            function cancel() {
                location.href = '<%=requestPath%>.jsp?wizard=finish';
            }

            CARBON.showConfirmationDialog('<fmt:message key="confirmation.workflow.add.abort"/> ' + name + '?',
                    cancel, null);
        }


        var stepOrder = 0;
        jQuery(document).ready(function(){
            jQuery('h2.trigger').click(function(){
                if (jQuery(this).next().is(":visible")) {
                    this.className = "active trigger step_heads";
                } else {
                    this.className = "trigger step_heads";
                }
                jQuery(this).next().slideToggle("fast");
                return false; //Prevent the browser jump to the link anchor
            });
            jQuery('#stepsAddLink').click(function(){
                stepOrder++;
                jQuery('#stepsConfRow').append(jQuery('<div id="div_step_head_'+stepOrder+'" style="border:solid 1px #ccc;padding: 10px;"><h2 id="step_head_'+stepOrder+'" class="sectionSeperator trigger active step_heads" style="background-color: beige; clear: both;">' +
                                                      '<input type="hidden" value="'+stepOrder+'" name="approve_step" id="approve_step">' +
                                                      '<a class="step_order_header" href="#">Step '+stepOrder+'</a>' +
                                                      '<a onclick="deleteStep(this);return false;" href="#" class="icon-link" style="background-image: url(images/delete.gif);float:right;width: 9px;"></a>' +
                                                      '</h2>' +
                                                      '<table><tr><td colspan="2" id="users_step_head_'+stepOrder+'"></td></tr><tr><td>Users</td><td><textarea onclick="moveSearchController(\''+stepOrder+'\',\'users\');" name="p-step-'+stepOrder+'-users" id="p-step-'+stepOrder+'-users" rows="3" cols="100"></textarea></td></tr>' +
                                                      '<tr><td colspan="2" id="roles_step_head_'+stepOrder+'"></td></tr><tr><td>Roles</td><td><textarea onclick="moveSearchController(\''+stepOrder+'\',\'roles\');" name="p-step-'+stepOrder+'-roles" id="p-step-'+stepOrder+'-roles" rows="3" cols="100"></textarea></td></tr>' +
                                                      '</table></div>'));
            });

        });

        function moveSearchController(step, category){

            $("#id_search_controller").detach().appendTo("#"+category+"_step_head_"+step);
            $("#id_search_controller").show();
            $("#currentstep").val(step);

            loadCategory(category);
        }




        function deleteStep(obj){

            $("#id_search_controller").hide();
            $("#id_search_controller").detach().appendTo("#id_search_controller_base");

            stepOrder--;
            jQuery(obj).parent().next().remove();
            jQuery(obj).parent().parent().remove();
            if($('.step_heads').length > 0){
                var newStepOrderVal = 1;
                $.each($('.step_heads'), function(){
                    var oldApproveStepVal = parseInt($(this).find('input[name="approve_step"]').val());

                    //Changes in header
                    $(this).attr('id','step_head_'+newStepOrderVal);
                    $(this).find('input[name="approve_step"]').val(newStepOrderVal);
                    $(this).find('.step_order_header').text('Step '+newStepOrderVal);

                    var textArea_Users = $('#p-step-'+oldApproveStepVal+'-users');
                    textArea_Users.attr('id','#p-step-'+newStepOrderVal+'-users');
                    textArea_Users.attr('name','#p-step-'+newStepOrderVal+'-users');

                    var textArea_Roles = $('#p-step-'+oldApproveStepVal+'_roles');
                    textArea_Roles.attr('id','#p-step-'+newStepOrderVal+'_roles');
                    textArea_Roles.attr('name','#p-step-'+newStepOrderVal+'_roles');

                    newStepOrderVal++;
                });
            }
        }

        function getSelectedItems(allList, category){
            if(allList!=null && allList.length!=0) {
                var currentStep = $("#currentstep").val();
                var currentValues = $("#p-step-" + currentStep + "-" + category).val();
                if (currentValues == null || currentValues == "") {
                    $("#p-step-" + currentStep + "-" + category).val(allList);
                } else {
                    var currentItems = currentValues.split(",");

                    for(var i=0;i<allList.length;i++){
                        var newItem = allList[i];
                        var tmp = newItem ;
                        for(var j=0;j<currentItems.length;j++){
                            var currentItem = currentItems[j];
                            if(newItem == currentItem){
                                tmp = null ;
                                break;
                            }
                        }
                        if(tmp!=null){
                            currentValues = currentValues + "," + tmp ;
                        }
                    }
                    $("#p-step-" + currentStep + "-" + category).val(currentValues);
                }

            }

        }

        function selectTemplate(){
            var workflowForm = document.getElementById("id_workflow_template");
            workflowForm.submit();
        }

    </script>

    <div id="middle">
        <h2><fmt:message key='workflow.add'/></h2>

        <div id="workArea">
            <table border="1">
                <tr>
                    <td>
                        <form id="id_workflow_template" method="post" name="serviceAdd" action="template-params.jsp">
                            <input type="hidden" name="path" value="<%=requestPath%>"/>
                            <select onchange="selectTemplate();" id="id_template" name="<%=WorkflowUIConstants.PARAM_WORKFLOW_TEMPLATE%>"
                                    style="min-width: 30%">
                                <option value="" disabled selected><fmt:message key="select"/></option>
                                <%
                                    for (TemplateBean templateTmp : templateList) {
                                %>
                                <option value="<%=templateTmp.getId()%>"
                                        <%=templateTmp.getId().equals(template) ? "selected" : ""%>>
                                    <%=templateTmp.getName()%>
                                </option>
                                <%
                                    }
                                %>
                            </select>
                        </form>
                    </td>
                </tr>
            </table>


            <%
                if(template != null ){
            %>
            <form method="post" name="serviceAdd" action="template-impl-params.jsp">
                <input type="hidden" name="path" value="<%=requestPath%>"/>
                <input type="hidden" name="<%=WorkflowUIConstants.PARAM_WORKFLOW_TEMPLATE%>" value="<%=template%>">
                <input type="hidden" name="<%=WorkflowUIConstants.PARAM_WORKFLOW_NAME%>" value="<%=workflowName%>">
                <input type="hidden" name="<%=WorkflowUIConstants.PARAM_WORKFLOW_DESCRIPTION%>"
                       value="<%=description%>">
                <table class="styledLeft">
                    <thead>
                    <tr>
                        <th><fmt:message key="workflow.details"/></th>
                    </tr>
                    </thead>
                    <tr>
                        <td width="30%"><fmt:message key='workflow.template'/></td>
                        <td>

                        </td>
                    </tr>
                    <tr>
                        <td class="formRow">
                            <table class="normal" style="width: 100%;">
                                <%
                                    boolean emptyList = true;
                                    for (TemplateParameterDef parameter : templateDTO.getParameters()) {
                                        if (parameter != null) {
                                            emptyList = false;
                                            break;
                                        }
                                    }

                                    if (emptyList) {
                                %>
                                <tr>
                                    <td colspan="2"><fmt:message key="workflow.template.has.no.params"/></td>
                                </tr>
                                <%
                                } else {
                                    for (TemplateParameterDef parameter : templateDTO.getParameters()) {
                                        if (parameter != null) {
                                %>
                                <tr>
                                    <td width="200px" style="vertical-align: top !important;"><%=parameter.getDisplayName()%>
                                    </td>
                                    <%
                                        //Text areas
                                        if (WorkflowUIConstants.ParamTypes.LONG_STRING
                                                .equals(parameter.getParamType())) {
                                    %>
                                    <td><textarea name="p-<%=parameter.getParamName()%>"
                                                  title="<%=parameter.getDisplayName()%>" style="min-width: 30%"
                                            ><%=templateParams.get("p-" + parameter.getParamName()) != null ?
                                            templateParams.get("p-" + parameter.getParamName()) : ""%></textarea>
                                    </td>
                                    <%
                                    } else if (WorkflowUIConstants.ParamTypes.BPS_PROFILE
                                            .equals(parameter.getParamType())) {
                                        //bps profiles
                                    %>
                                    <td><select name="p-<%=parameter.getParamName()%>" style="min-width: 30%">
                                        <%
                                            for (BPSProfileDTO bpsProfile : bpsProfiles) {
                                                if (bpsProfile != null) {
                                                    boolean select = bpsProfile.getProfileName().equals(
                                                            templateParams.get("p-" +
                                                                    parameter.getParamName()));
                                        %>
                                        <option value="<%=bpsProfile.getProfileName()%>" <%=select ? "selected" :
                                                ""%>><%=bpsProfile.getProfileName()%>
                                        </option>
                                        <%
                                                }
                                            }
                                        %>
                                    </select>
                                    </td>
                                    <%
                                    } else if (WorkflowUIConstants.ParamTypes.USER_NAME_OR_USER_ROLE
                                            .equals(parameter.getParamType())) {
                                    %>
                                    <td>
                                       <a id="stepsAddLink" class="icon-link" style="float:none;margin-left:0; padding-bottom:10px;"><fmt:message key='workflow.template.button.add.step'/></a>
                                        <div style="margin-bottom:10px;width: 75%" id="stepsConfRow">

                                        </div>

                                    </td>
                                    <%
                                    } else {
                                        //other types
                                        String type = "text";
                                        if (WorkflowUIConstants.ParamTypes.BOOLEAN
                                                .equals(parameter.getParamType())) {
                                            type = "checkbox";
                                        } else if (WorkflowUIConstants.ParamTypes.INTEGER
                                                .equals(parameter.getParamType())) {
                                            type = "number";
                                        } else if (WorkflowUIConstants.ParamTypes.PASSWORD
                                                .equals(parameter.getParamType())) {
                                            type = "password";
                                        }
                                    %>
                                        <%--Appending 'p-' to differentiate dynamic params--%>
                                    <td>


                                        <input name="p-<%=parameter.getParamName()%>" style="min-width: 30%"
                                               value='<%=templateParams.get("p-" + parameter.getParamName()) != null ?
                                                templateParams.get("p-" + parameter.getParamName()) : ""%>'
                                               type="<%=type%>">
                                    </td>
                                    <%

                                            }
//                            todo:handle 'required' value

                                        }
                                    %>
                                </tr>
                                <%
                                        }
                                    }

                                %>
                            </table>
                        </td>
                    </tr>
                </table>
                <br/>
                <table class="styledLeft">

                    <tr>
                        <td class="buttonRow">
                            <input class="button" value="<fmt:message key="back"/>" type="button" onclick="goBack();">
                            <input class="button" value="<fmt:message key="next"/>" type="submit"/>
                            <input class="button" value="<fmt:message key="cancel"/>" type="button"
                                   onclick="doCancel();"/>
                        </td>
                    </tr>
                </table>
                <br/>
            </form>
            <%
                }
            %>
        </div>
    </div>
    <div id="id_search_controller_base">
        <div id="id_search_controller" style="display:none;">
            <input type="hidden" id="currentstep" name="currentstep" value=""/>
            <div id="id_user_search">
                <jsp:include page="../search/user-role-search.jsp">
                    <jsp:param name="navigator-holder" value="id-result-holder"/>
                    <jsp:param name="result-holder" value="id-navigator-holder"/>
                    <jsp:param name="function-get-all-items" value="getSelectedItems"/>
                </jsp:include>
            </div>
            <div id="id-result-holder">

            </div>
            <div id="id-navigator-holder">

            </div>
        </div>
    </div>


</fmt:bundle>