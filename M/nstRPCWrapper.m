nstRPCWrapper ; NST - VistA RPC wrapper ; 02/25/2014 11:56PM
 ;;
 ;;	Author: Nikolay Topalov
 ;;
 ;;	Copyright 2014 Nikolay Topalov
 ;;
 ;;	Licensed under the Apache License, Version 2.0 (the "License");
 ;;	you may not use this file except in compliance with the License.
 ;;	You may obtain a copy of the License at
 ;;	http://www.apache.org/licenses/LICENSE-2.0
 ;;	Unless required by applicable law or agreed to in writing, software
 ;;	distributed under the License is distributed on an "AS IS" BASIS,
 ;;	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 ;;	See the License for the specific language governing permissions and
 ;;	limitations under the License.
 ;;
 Q
 ;
rpcExecute(TMP) ;
 ;
 ; Execute an RPC based on paramaters provided in TMP reference global
 ;
 ; Input parameter
 ; ================
 ;
 ; TMP is a reference to a global with nodes. e.g.,  ^TMP("ewd",$J,"RPC")
 ; 
 ;   ,"name")      NAME (#8994, .01)
 ;   ,"version")   VERSION (#8994, .09)
 ;   ,"use") = L|R
 ;   ,"input",n,"type")   PARAMETER TYPE (#8994.02, #02)
 ;   ,"input",n,"value")  input parameter value
 ;      e.g.
 ;      ,"input",n,"type")="LITERAL"
 ;      ,"input",n,"value")="abc"
 ;
 ;      ,"input",n,"type")="REFERENCE"
 ;      ,"input",n,"value")="^ABC"
 ;
 ;      ,"input",n,"type")="LIST"
 ;      ,"input",n,"value",m1)="list1"
 ;      ,"input",n,"value",m2,k1)="list21"
 ;      ,"input",n,"value",m2,k2)="list22"
 ;          
 ;          where m1, m2, k1, k2 are numbers or strings 
 ;      
 ; Output value
 ; ==============
 ; The RPC output is in  @TMP@("result") 
 ;  e.g., ,"result","type")="SINGLE VALUE"
 ;                  "value")="Hello World!"
 ;                 
 ; Return {"success": result, "message" : message }
 ;    result 1 - success
 ;           0 - error
 ;
 N rpc,pRpc,tArgs,tCnt,tI,tOut,tResult,X
 N XWBAPVER,DUZ
 ;
 S U=$G(U,"^")  ; set default to "^"
 ;
 S pRpc("name")=$G(@TMP@("name"))
 Q:pRpc("name")="" $$error(-1,"RPC name is missing")
 ;
 S rpc("ien")=$O(^XWB(8994,"B",pRpc("name"),""))
 Q:'rpc("ien") $$error(-2,"Undefined RPC ["_pRpc("name")_"]")
 ;
 S XWBAPVER=$G(@TMP@("version"))
 S pRpc("use")=$G(@TMP@("use"))
 S pRpc("context")=$G(@TMP@("context"))
 S pRpc("duz")=$G(@TMP@("duz"))
 S pRpc("division")=$G(@TMP@("division"))
 ; Set DUZ
 S DUZ=pRpc("duz")
 S DUZ(2)=pRpc("division")
 S:DUZ DUZ(0)=$P(^VA(200,DUZ,0),U,4)
 ;
 S X=$G(^XWB(8994,rpc("ien"),0)) ;e.g., XWB EGCHO STRING^ECHO1^XWBZ1^1^R
 S rpc("routineTag")=$P(X,"^",2)
 S rpc("routineName")=$P(X,"^",3)
 Q:rpc("routineName") $$error(-4,"Undefined routine name for RPC ["_pRpc("name")_"]")
 ;
 ; 1=SINGLE VALUE; 2=ARRAY; 3=WORD PROCESSING; 4=GLOBAL ARRAY; 5=GLOBAL INSTANCE
 S rpc("resultType")=$P(X,"^",4)
 S rpc("resultWrapOn")=$P(X,"^",8)
 ;
 ; is the RPC available
 D CKRPC^XWBLIB(.tOut,pRpc("name"),pRpc("use"),XWBAPVER)
 Q:'tOut $$error(-3,"RPC ["_pRpc("name")_"] cannot be run at this time.") 
 ;
 S X=$$CHKPRMIT(pRpc("name"),pRpc("duz"),pRpc("context"))
 Q:X'="" $$error(-4,"RPC ["_pRpc("name")_"] is not allowed to be run: "_X)
 ;
 S X=$$buildArguments(.tArgs,rpc("ien"),TMP)  ; build RPC arguments list - tArgs
 Q:X<0 $$error($P(X,U),$P(X,U,2)) ; error building arguments list
 ;
 ; now, prepare the arguments for the final call
 ; it is outside of the $$buildArgumets so we can newed the individual parameters
 S (tI,tCnt)=""
 F  S tI=$O(tArgs(tI)) Q:tI=""  F  S tCnt=$O(tArgs(tI,tCnt)) Q:tCnt=""  N @("tA"_tI) X tArgs(tI,tCnt)  ; set/merge actions
 ;
 S X="D "_rpc("routineTag")_"^"_rpc("routineName")_"(.tResult"_$S(tArgs="":"",1:","_tArgs)_")"
 X X  ; execute the routine
 M @TMP@("result","value")=tResult
 S @TMP@("result","type")=$$EXTERNAL^DILFD(8994,.04,,rpc("resultType"))
 Q $$success()
 ;
 ;
isInputRequired(pIEN,pSeqIEN) ; is input RPC parameter is required
 ; pIEN - RPC IEN in file #8994
 ; pSeqIEN - Input parameter IEN in multiple file #8994.02
 ;
 Q $P(^XWB(8994,pIEN,2,pSeqIEN,0),U,4)=1
 ;
buildArguments(out,pIEN,TMP) ;Build RPC argument list
 ;
 ; Return values
 ; =============
 ; Success 1
 ; Error   -n^error message
 ;
 ; out array with arguments
 N tCnt,tError,tIEN,tI,tII,tRequired,tParam,tIndexSeq,X
 ;
 S tI=0
 S tII=""
 S tCnt=0
 ;
 K out
 S out=""
 S tError=0
 S tIndexSeq=$D(^XWB(8994,pIEN,2,"PARAMSEQ"))  ; is the cross-reference defined
 S tParam=$S(tIndexSeq:"^XWB(8994,pIEN,2,""PARAMSEQ"")",1:"^XWB(8994,pIEN,2)")
 ;
 F  S tI=$O(@tParam@(tI)) Q:('tI)!(tError)  D
 . S tII=$O(@TMP@("input",tII))
 . S tIEN=$S(tIndexSeq:$O(@tParam@(tI,"")),1:tI)  ; get the IEN of the input parameter
 . S tRequired=$$isInputRequired(pIEN,tIEN)
 . I tRequired,'$D(@TMP@("input",tII,"value")) S tError="-5^Required input paramater is missing." Q
 . I '$D(@TMP@("input",tII,"value")) S out=out_"," Q
 . I $D(@TMP@("input",tII,"value"))=1 D  Q
 . . S out=out_"tA"_tI_","   ; add the argument
 . . I $$UP^XLFSTR($G(@TMP@("input",tII,"type")))="REFERENCE" D
 . . . S tCnt=tCnt+1,out(tI,tCnt)="S tA"_tI_"=@@TMP@(""input"","_tII_",""value"")"  ; set it
 . . . Q 
 . . E  S tCnt=tCnt+1,out(tI,tCnt)="S tA"_tI_"=@TMP@(""input"","_tII_",""value"")"  ; set it as action for later
 . . Q
 . ; list/array
 . S out=out_".tA"_tI_","
 . S tCnt=tCnt+1,out(tI,tCnt)="M tA"_tI_"=@TMP@(""input"","_tII_",""value"")"  ; merge it
 . Q
 ;
 Q:tError tError
 S out=$E(out,1,$L(out)-1)
 Q 1
 ;
formatResult(code,message) ; return JSON formatted result
 Q "{""success"": "_code_", ""message"": """_$S($TR(message," ","")="":"",1:message)_"""}"
 ;
error(code,message) ;
 Q $$formatResult(0,code_" "_message)
 ;
success(code,message) ;
 Q $$formatResult(1,$G(code)_" "_$G(message))
 ;
 ; Is RPC pertmited to run in a context?
CHKPRMIT(pRPCName,pUser,pContext) ;checks to see if remote procedure is permited to run
 ;Input:  pRPCName - Remote procedure to check
 ;        pUser    - User
 ;        pContext - RPC Context
 Q:$$KCHK^XUSRB("XUPROGMODE",pUser) ""  ; User has programmer key
 N result,X
 N XQMES
 S U=$G(U,"^")
 S result="" ;Return XWBSEC="" if OK to run RPC
 ;
 ;In the beginning, when no DUZ is defined and no context exist,
 ;setup default signon context
 S:'$G(pUser) pUser=0,pContext="XUS SIGNON"   ;set up default context
 ;
 ;These RPC's are allowed in any context, so we can just quit
 S X="^XWB IM HERE^XWB CREATE CONTEXT^XWB RPC LIST^XWB IS RPC AVAILABLE^XUS GET USER INFO^XUS GET TOKEN^XUS SET VISITOR^"
 S X=X_"XUS KAAJEE GET USER INFO^XUS KAAJEE LOGOUT^"  ; VistALink RPC's that are always allowed.
 I X[(U_pRPCName_U) Q result
 ;
 ;
 ;If in Signon context, only allow XUS and XWB rpc's
 I $G(pContext)="XUS SIGNON","^XUS^XWB^"'[(U_$E(pRPCName,1,3)_U) Q "Application context has not been created!"
 ;XQCS allows all users access to the XUS SIGNON context.
 ;Also to any context in the XUCOMMAND menu.
 ;
 I $G(pContext)="" Q "Application context has not been created!"
 ;
 S X=$$CHK^XQCS(pUser,pContext,pRPCName)         ;do the check
 S:'X result=X
 Q result