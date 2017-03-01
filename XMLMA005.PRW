#INCLUDE "PROTHEUS.CH"
#include "RWMAKE.CH"
#include "Colors.CH"
#include "Font.CH"
#Include "HBUTTON.CH"
#include "Topconn.CH"

//Informa a versao do Programa, conforme no JEDI
Static Versao	:= "V1.01"   

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³XMLMA005  ºAutor  ³Marcos Santos       º Data ³  06/12/16   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Programa para Efetuar entrada da pre-nota, apos conferencia,º±±
±±º          ³No Protheus, atraves de rotina automatica.                  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function XMLMA005()
	Local cFiltro       := ""           
	Private	 aCores		:=	{{"UP2_REPROV == 'S'" ,	"BR_VERMELHO"	},;	// "Arquivo Rejeitado" 
							{ "UP2_STATUS == 'P'" ,	"BR_VERDE"		},;	// "XML integrado ao Protheus" 
							{ "UP2_STATUS == 'C'" ,	"BR_AMARELO"	},; // "Conferencia Comercial"
							{ "UP2_STATUS == 'F'" ,	"BR_LARANJA"	}}	// "Conferencia Fisica"

	Private	aLegenda    := {}
	Private	cTitulo		:= "Manutenção de Arquivos XML - " + Versao 
	Private	cAlias		:= "UP2"
	Private	cCadastro	:= cTitulo
	Private	aRotina		:= {}
    Private lTolera     := SuperGetMv("XML_TOL" , .F. , .F. ,/*cFilial*/)         //Se vai considerar a tolerancia
    Private lCpoxPed    := SuperGetMV("XML_CPXPED" , .F. , .F.  ,  /*cFilial*/)   //Se eh obrigatorio ter o pedido de compra
    Private lCRxPed     := SuperGetMV("XML_CRXPED" , .F. , .F.  ,  /*cFilial*/)   //Se encaminha para o fisico se tiver algum item criticado
	Private lPCxPed     := SuperGetMV("XML_PCXPED" , .F. , .F.  ,  /*cFilial*/)   //Se todos os itens tem que ter pedido de compra
    Private lPCLib      := SuperGetMV("XML_PCLIB"  , .F. , .F.  ,  /*cFilial*/)   //Somente filtra pedidos de compra liberados
    
    Private aColsEx     := {}
    Private aColsExD    := {}
	
	aAdd(aRotina,{"Pesquisar"                , "AxPesqui"   , 0, 1})
	aAdd(aRotina,{"Visualizar"               , "U_XMLMA05F" , 0, 2})
	aAdd(aRotina,{"Encaminhar"               , "U_XMLMA05F" , 0, 3})
	aAdd(aRotina,{"Legenda"                  , "U_LEGMA05()", 0, 4})
	aAdd(aRotina,{"Extrair XML"              , "U_EXTMA05()", 0, 5})
	aAdd(aRotina,{"Cancelar XML"             , "U_CANMA05()", 0, 6})
	
	DbSelectArea("UP2")
	DbSetOrder(1) 
	
	cFiltro := "UP2_FILIAL='"+xFilial("UP2")+"'"
    Set Filter To &cFiltro
	
	CursorWait()
    CursorArrow()

	mBrowse(6,1,22,75,cAlias,,,,,,aCores,,,,,.F.,.F.,.F.,)
Return 


User Function LEGMA05()
	aLegenda := {{ "BR_VERDE"	,"XML integrado ao Protheus"  },;
				{ "BR_VERMELHO"	,"Arquivo XML Cancelado"	  },;
				{ "BR_AMARELO"	,"Conferencia Comercial"	  },;
				{ "BR_LARANJA"	,"Conferencia Física"	      }}
	
	BrwLegenda(cTitulo,"Legenda",aLegenda)                             
Return()        


User Function XMLMA05F(cAlias,nReg,nOpc)
	Local	_lRet		:= .F.
	Local	aArea		:= GetArea()
	Local	aButtons	:= {}
	Local	aAcho		:= {}
	Local	aAlter		:= {}
	Local	aSize 		:= ()
	Local	aInfo		:= {}
	Local	aObjects 	:= {}
	Local	aPosObj    	:= {}
	Local	cOpcao		:= "VISUALIZAR"
	Local	nLeft		:= 0
	Local	nOpcGet		:= 2
	Local	oDlg		:= {}
	Local	oEnchoice	:= {}
	Local	oPanel3		:= {}
	
	Private	oGetDados	:= {}
		
	//2-visualiza, 3-encaminha 
	If UP2->UP2_STATUS == "P" .And. nOpc == 3
		MsgAlert("Nota/CTE ja processado.",cTitulo)
		Return
	EndIf

	If UP2->UP2_REPROV == "S" .And. nOpc == 3
		MsgAlert("Nota/CTE rejeitado.",cTitulo)
		Return
	EndIf
	
	DbSelectArea("UP2")
	DbSetOrder(1)
	
	RegToMemory("UP2",(cOpcao=="INCLUIR"))
	nUsado:=0
	
	DbSelectArea("SX3")
	DbSetOrder(1) 
	DbSeek("UP3")        
	
	aHeader:={}
	
	While !Eof().And.(x3_arquivo=="UP3")
		If Alltrim(x3_campo)=="UP3_DOC" .Or. Alltrim(x3_campo)=="UP3_SERIE"
			dbSkip()
			Loop
		Endif
		
		If Alltrim(x3_campo)=="UP3_ID_PAI" 
			nUsado:=nUsado+1
			Aadd(aHeader,{ TRIM("Id Item"),;
							x3_campo,;
							x3_picture,;
							x3_tamanho,;
							x3_decimal,;
							"AllwaysTrue()",;
							x3_usado,;
							x3_tipo,;
							x3_arquivo,;
							x3_context } )
		ElseIf X3USO(x3_usado) .And. cNivel>=x3_nivel .And. X3_BROWSE = "S"
			nUsado:=nUsado+1
			Aadd(aHeader,{ TRIM(x3_titulo),;
							x3_campo,;
							x3_picture,;
							x3_tamanho,;
							x3_decimal,;
							"AllwaysTrue()",;
							x3_usado,;
							x3_tipo,;
							x3_arquivo,;
							x3_context } )
		Endif
		dbSkip()
	End
	
	If cOpcao == "VISUALIZAR"
		aCols := {}
		CgaCols(@aCols)
	Endif
	
	If Len(aCols)>0
		cAliasEnc	:= "UP2"
		cAliasGetD	:= "UP3"
		cLinOk		:= "AllwaysTrue()"
		cTudOk		:= "AllwaysTrue()"
		cFieldOk	:= "U_XML05OK()"

		//Definicao do tamanho do dialogo e dos objetos
		aSize := MsAdvSize(.F./*lEnchoice*/,	.F.,)
		aInfo := { aSize[1], aSize[2], aSize[3], aSize[4], 1, 1, 1, 1}
		AAdd( aObjects, { 100, 040, .T., .T.,	.F. } )
		AAdd( aObjects, { 100, 055, .T., .T.,	.F. } )	
		AAdd( aObjects, { 100, 005, .T., .T.,	.T. } )	
		aPosObj := MsObjSize( aInfo, aObjects, .T. )
		
		//Campos que serao exibidos no Enchoice
		aAcho		:= {"NOUSER","UP2_TIPO ","UP2_FORMUL","UP2_DOC   ","UP2_SERIE ","UP2_ESPEC1","UP2_VOLUME","UP2_PLIQUI","UP2_PBRUTO",;
						"UP2_EMISSA","UP2_FORNEC","UP2_LOJA  ","UP2_NOME  ","UP2_ESPECI","UP2_PROCES","UP2_CHVNFE",;
						"UP2_USER  ","UP2_NOMUSE","UP2_DATA  ","UP2_HORA  ","UP2_CRITIC",;
						"UP2_USRCOM","UP2_NOMCOM","UP2_DATCOM","UP2_HORACO","UP2_USREXP","UP2_NOMEXP","UP2_DATEXP","UP2_HORAEX",;
						"UP2_REPROV","UP2_USRREP","UP2_NOMREP","UP2_DTREPR","UP2_HORARP","UP2_MOTIVO",;
						"UP2_STATUS","UP2_BASE  ","UP2_VICMS ","UP2_BCST  ","UP2_VST   ","UP2_VTOTAL","UP2_VFRETE",;
						"UP2_VSEGUR","UP2_VDESC ","UP2_VII   ","UP2_VIPI  ","UP2_VPIS  ","UP2_VCOFIN","UP2_VOUTRO","UP2_VNF   "}

    	If nOpc == 3 .And. (UP2->UP2_STATUS = 'C' .Or. UP2->UP2_STATUS = 'F')
			aAlter		:= {"UP3_COD"}
			//lEdtProd	:= .T.
			nOpcGet		:= 3
		EndIf
		
		oDlg		:= MsDialog():New(aSize[7],0,aSize[6],aSize[5],cTitulo,,,,,CLR_BLUE,/*nClrBack*/,,, .T.,,,,,)
		oEnchoice	:= Msmget():New(cAliasEnc,,2,,,,aAcho,{aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4]},,3,,,,oDlg,,/*lVirtual*/,,,,,,,,.T.)       
		oGetDados	:= MsGetDados():New(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],nOpcGet,cLinOk,cTudOk,"",.F.,aAlter,,,,cFieldOk,,,,oDlg)

		//Quantidade maxima de linhas no grid
		oGetDados:nMax := Len(aCols)
		
		oPanel3		:= TPanel():New(aPosObj[3,1],aPosObj[3,2],/*cText*/,oDlg,/*oFont*/,.T./*lCentered*/,/*uParam7*/,/*nClrText*/,16118251/*nClrBack*/,aPosObj[3,3]/*nWidth*/ ,aPosObj[3,4]/*nHeight*/,.F./*lLowered*/,.F./*lRaised*/ )

		//Processamento
		If nOpc == 3 .And. UP2->UP2_STATUS <> "P"
			//Caso esteja para conferencia do setor de compras
			If UP2->UP2_STATUS == "C"
				oBtnConfir	:= TButton():New(c(002),aPosObj[3,3]-C(100),"Conferência Física",oPanel3,{|| Confere(), _lRet:= .F., oDlg:End() },nLeft := C(050),C(010),,/*oFont*/,,.T.,,,,/*bWhen*/,,)
			//Caso esteja para conferencia da expedicao, e geracao da pre nota
			ElseIf UP2->UP2_STATUS == "F"
				oBtnConfir	:= TButton():New(c(002),aPosObj[3,3]-C(100),"Gerar Pre-Nota ",oPanel3,{|| _lRet:= .T., oDlg:End() },nLeft := C(050),C(010),,/*oFont*/,,.T.,,,,/*bWhen*/,,)
			EndIf
		EndIf
		
		//Cancelar
		oBtnCancel	:= TButton():New(c(002),aPosObj[3,3]-C(040),"Voltar" ,oPanel3,{|| _lRet:= .F., oDlg:End()},C(030),C(010),,,.F.,.T.,.F.,,.F.,,,.F.)//,,/*oFont*/,,.T.,,,,/*bWhen*/,,)
		
		//botoes de duplicar e somar
		If nOpc == 3 .And. UP2->UP2_STATUS == "C"
			oBtnDupl	:= TButton():New(c(002),aPosObj[3,3]-C(160),"Duplicar Linha"  ,oPanel3,{|| Duplica(), _lRet:= .F., },C(050),C(010),,,.F.,.T.,.F.,,.F.,,,.F.)//,,/*oFont*/,,.T.,,,,/*bWhen*/,,)
			oBtnSoma	:= TButton():New(c(002),aPosObj[3,3]-C(220),"Somar Linha"     ,oPanel3,{||  SomaLn(), _lRet:= .F., },C(050),C(010),,,.F.,.T.,.F.,,.F.,,,.F.)//,,/*oFont*/,,.T.,,,,/*bWhen*/,,)
			
			//botao pedido de compra
			If lCpoxPed	
		    	oBtnPC	:= TButton():New(c(002),aPosObj[3,3]-C(280),"Pedido de Compra",oPanel3,{||  PedCom(), _lRet:= .F., },C(050),C(010),,,.F.,.T.,.F.,,.F.,,,.F.)//,,/*oFont*/,,.T.,,,,/*bWhen*/,,)
			Endif
		Endif 

		oDlg:lMaximized := .T.
		oDlg:Activate()
	
		If _lRet .And. nOpc == 3 .And. UP2->UP2_STATUS = 'F' //conferencia fisica
            If MsgYesNo("Deseja realmente gerar a Pré-Nota?",cTitulo)
				Processa({|| u_Prt05Ex("UP2",nReg,3)}, "Manutenção XML", "Aguarde... Processando...", .F.)
			Endif	
		Endif
	Endif 
	
	RestArea(aArea)
Return

Static Function Duplica()
	Local nPosQTDE	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_QUANT"})
	Local nPosRECNO	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_ID_PAI"})
	Local nPosDescr := Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_DESCR"})
    Local cPerg     := "PRT05D"
    Local nQtdeNew  := 0
    Local nQtdeAtu  := 0
    Local nQtdeCal  := 0
    Local nVlrTotal := 0
    Local nICMS     := 0
    Local nIPI      := 0
    Local nPIS      := 0
    Local nCOF      := 0
    Local cQuery    := ""
    Local cDescr    := "" 
    
	If MsgYesNo("Deseja realmente duplicar a linha da nota?", cCadastro)
		
		//descricao do item
		cDescr   := aCols[oGetDados:oBrowse:nAt, nPosDescr] 
		
		//busco a quantidade que esta posicionada
		nQtdeAtu := aCols[oGetDados:oBrowse:nAt, nPosQTDE]
		
		//tenho que apresentar o pergunte
		SX1_022(cPerg)
   
		//Apresenta parametros para pesquisa, obrigatorio informar
		While !Pergunte (cPerg,.T.,cCadastro) 
		Enddo          
	
		//caso o usuario informou uma qtde maior
		nQtdeNew := MV_PAR01
		
		If nQtdeNew = 0
			Return()
		Endif
		
		While nQtdeNew >= nQtdeAtu
			Pergunte (cPerg,.T.,cCadastro) 
			nQtdeNew := MV_PAR01
		Enddo          
		
		//tenho que abrir o registro original da UP3
		cQuery := ""
		cQuery := " SELECT * FROM  " + RetSqlName("UP3")
		cQuery += " WHERE D_E_L_E_T_ <> '*' "
		cQuery += " AND UP3_FILIAL = '"+xFilial("UP2")+"'"
		cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
		cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
		cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
		cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
		cQuery += " AND R_E_C_N_O_ = "+cValToChar(aCols[oGetDados:oBrowse:nAt, nPosRECNO])
		VerTabela("TRB22DT")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRB22DT",.T.,.T.)
                        
   		//qtde com a diferenca
		nQtdeCal  := nQtdeAtu - nQtdeNew
		nVlrTotal := Round(TRB22DT->UP3_VUNIT * nQtdeCal,2)
	    nICMS     := Round(nVlrTotal * TRB22DT->UP3_PICMS  / 100, 2)
    	nIPI      := Round(nVlrTotal * TRB22DT->UP3_PIPI   / 100, 2)
        nPIS      := Round(nVlrTotal * TRB22DT->UP3_PPIS   / 100, 2)
        nCOF      := Round(nVlrTotal * TRB22DT->UP3_PCOFIN / 100, 2)
	    
	    //atualizo o registro atual da UP3
	    cQuery := ""
	    cQuery := " UPDATE " + RetSqlName("UP3")
		cQuery += " SET UP3_QUANT = "+cValToChar(nQtdeCal)
		cQuery += " ,UP3_TOTAL = "+cValToChar(nVlrTotal)
		cQuery += " ,UP3_VICMS = "+cValToChar(nICMS)
		cQuery += " ,UP3_VIPI = "+cValToChar(nIPI)
		cQuery += " ,UP3_VPIS = "+cValToChar(nPIS)
		cQuery += " ,UP3_VCOFIN = "+cValToChar(nCOF)
		cQuery += " ,UP3_TOTIMP = "+cValToChar(nVlrTotal)
		cQuery += " WHERE D_E_L_E_T_ <> '*' "
		cQuery += " AND UP3_FILIAL = '"+xFilial("UP2")+"'"
		cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
		cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
		cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
		cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
		cQuery += " AND R_E_C_N_O_ = "+cValToChar(aCols[oGetDados:oBrowse:nAt, nPosRECNO])
		TcSqlExec(cQuery)

        //tenho que gerar o novo registro
		nVlrTotal := Round(TRB22DT->UP3_VUNIT * nQtdeNew,2)
		
		DbSelectArea("UP3")
	    UP3->(DbSetOrder(1))
	    UP3->(DbGoTop())
    	
    	RecLock("UP3",.T.)
	    UP3->UP3_FILIAL := xFilial("UP3")  
	    
	    cQuery := ""
		cQuery := " SELECT MAX(UP3_SEQ)+1 TOTAL"
		cQuery += " FROM  " + RetSqlName("UP3")
		cQuery += " WHERE D_E_L_E_T_ <> '*' "
		cQuery += " AND UP3_FILIAL = '"+xFilial("UP2")+"'"
		cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
		cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
		cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
		cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
		cQuery += " AND UP3_ID_PAI = '"+cValToChar(UP2->(Recno()))+"'"
		VerTabela("TRB22SQ")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRB22SQ",.T.,.T.)
		
	    UP3->UP3_SEQ    := STRZERO(TRB22SQ->TOTAL,3)
	    VerTabela("TRB22SQ")

	    UP3->UP3_DESCR	:= cDescr
	    UP3->UP3_DOC    := UP2->UP2_DOC
	    UP3->UP3_SERIE  := UP2->UP2_SERIE
	    UP3->UP3_EMISSA := UP2->UP2_EMISSA
	    UP3->UP3_FORNEC := UP2->UP2_FORNEC
	    UP3->UP3_LOJA   := UP2->UP2_LOJA
	    UP3->UP3_COD    := TRB22DT->UP3_COD
	    UP3->UP3_QUANT  := nQtdeNew
	    UP3->UP3_VUNIT  := TRB22DT->UP3_VUNIT
	    UP3->UP3_TOTAL  := nVlrTotal
	    UP3->UP3_CRITIC := ""
	    UP3->UP3_CFOP   := TRB22DT->UP3_CFOP

	    //Informacoes de impostos dos itens
	    UP3->UP3_NCM    := TRB22DT->UP3_NCM
	    UP3->UP3_VICMS  := Round(nVlrTotal * TRB22DT->UP3_PICMS / 100,2)
	    UP3->UP3_PICMS  := TRB22DT->UP3_PICMS
	    UP3->UP3_VIPI   := Round(nVlrTotal * TRB22DT->UP3_PIPI / 100,2)
	    UP3->UP3_PIPI   := TRB22DT->UP3_PIPI
	    UP3->UP3_VPIS   := Round(nVlrTotal * TRB22DT->UP3_PPIS / 100,2)
	    UP3->UP3_PPIS   := TRB22DT->UP3_PPIS
	    UP3->UP3_VCOFIN := Round(nVlrTotal * TRB22DT->UP3_PCOFIN / 100,2)
	    UP3->UP3_PCOFIN := TRB22DT->UP3_PCOFIN
    
	    UP3->UP3_RATEIO := 0
    	UP3->UP3_TOTIMP := nVlrTotal
		UP3->UP3_PEDIDO := ""
		UP3->UP3_ITEMPC := ""
		UP3->UP3_UNCOM  := TRB22DT->UP3_UNCOM
		UP3->UP3_UNTRIB := TRB22DT->UP3_UNTRIB

	    //Informacoes do usuario e hora de processamento
	    UP3->UP3_USER   := RetCodUsr()
    	UP3->UP3_DATA   := Date()
	    UP3->UP3_HORA   := Time()
        UP3->UP3_VALDES := 0
	    UP3->UP3_CLASFI := TRB22DT->UP3_CLASFI
	    UP3->UP3_ID_PAI := TRB22DT->UP3_ID_PAI
	    UP3->(MsUnlock())
		VerTabela("TRB22DT")
		
		//carrega o acols
		aCols := {}
		CgaCols(@aCols)
		
		oGetDados:Refresh()
	Endif	
Return  

Static Function SomaLn()
	Local nPosQTDE	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_QUANT"})
	Local nPosRECNO	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_ID_PAI"})
	Local nPosTotal	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_TOTAL"})
	Local nPosICMS	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_VICMS"})
	Local nPosIPI	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_VIPI"})
	Local nPosPIS	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_VPIS"})
	Local nPosCOFIN	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_VCOFIN"}) 
	Local nPosCod	:= Ascan(aHeader,{|x| Alltrim(x[2]) ==  "UP3_COD"}) 
	
    Local cPerg     := "PRT05S"
    Local cSeq      := ""
    Local nQtdeAtu  := 0
    Local nQtdeCal  := 0
    Local nVlrTotal := 0
    Local nICMS     := 0
    Local nIPI      := 0
    Local nPIS      := 0
    Local nCOF      := 0
    Local cQuery    := ""
    
	If MsgYesNo("Deseja realmente somar a linha da nota?", cCadastro)

		//tenho que apresentar o pergunte
		SX1_22S(cPerg)
   
		//Apresenta parametros para pesquisa, obrigatorio informar
		While !Pergunte (cPerg,.T.,cCadastro) 
		Enddo          
	
		cSeq := AllTrim(MV_PAR01)
		
		If Empty(cSeq)
			Return()
		Endif
		
		//tenho que abrir o registro original da UP3 pra ver se existe
		cQuery := ""
		cQuery := " SELECT * FROM  " + RetSqlName("UP3")
		cQuery += " WHERE D_E_L_E_T_ <> '*' "
		cQuery += " AND UP3_FILIAL = '"+xFilial("UP2")+"'"
		cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
		cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
		cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
		cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
		cQuery += " AND R_E_C_N_O_ <> "+cValToChar(aCols[oGetDados:oBrowse:nAt, nPosRECNO])  //não pode ser no registro posicionado
		cQuery += " AND UP3_SEQ = '"+cSeq+"'"  //sequencia
		cQuery += " AND UP3_COD = '"+aCols[oGetDados:oBrowse:nAt, nPosCod]+"'"  //tem que ser o mesmo codigo de item
		cQuery += " AND UP3_ID_PAI = '"+cValToChar(UP2->(Recno()))+"'"
		
		VerTabela("TRB22DT")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRB22DT",.T.,.T.)
		
		If Empty(TRB22DT->UP3_COD)
			MsgAlert("Registro não encontrado, só é possível somar itens iguais.",cTitulo)
			Return()
		Endif
                        
   		//qtde com a diferenca
		nQtdeCal  := aCols[oGetDados:oBrowse:nAt, nPosQTDE]        + TRB22DT->UP3_QUANT
		nVlrTotal := Round(aCols[oGetDados:oBrowse:nAt, nPosTotal] + TRB22DT->UP3_TOTAL,2)
	    nICMS     := Round(aCols[oGetDados:oBrowse:nAt, nPosICMS]  + TRB22DT->UP3_VICMS,2)
    	nIPI      := Round(aCols[oGetDados:oBrowse:nAt, nPosIPI]   + TRB22DT->UP3_VIPI,2)
        nPIS      := Round(aCols[oGetDados:oBrowse:nAt, nPosPIS]   + TRB22DT->UP3_VPIS,2)
        nCOF      := Round(aCols[oGetDados:oBrowse:nAt, nPosCOFIN] + TRB22DT->UP3_VCOFIN,2)
	    
	    //atualizo o registro atual da UP3
	    cQuery := ""
	    cQuery := " UPDATE " + RetSqlName("UP3")
		cQuery += " SET UP3_QUANT = "+cValToChar(nQtdeCal)
		cQuery += " ,UP3_TOTAL = "+cValToChar(nVlrTotal)
		cQuery += " ,UP3_VICMS = "+cValToChar(nICMS)
		cQuery += " ,UP3_VIPI = "+cValToChar(nIPI)
		cQuery += " ,UP3_VPIS = "+cValToChar(nPIS)
		cQuery += " ,UP3_VCOFIN = "+cValToChar(nCOF)
		cQuery += " ,UP3_TOTIMP = "+cValToChar(nVlrTotal)
		cQuery += " ,UP3_PEDIDO = ' ' "
		cQuery += " ,UP3_ITEMPC = ' ' "
		cQuery += " WHERE D_E_L_E_T_ <> '*' "
		cQuery += " AND UP3_FILIAL = '"+xFilial("UP2")+"'"
		cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
		cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
		cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
		cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
		cQuery += " AND R_E_C_N_O_ = "+cValToChar(aCols[oGetDados:oBrowse:nAt, nPosRECNO])
		TcSqlExec(cQuery)

        //tenho que deletar o registro que usei para somar
		cQuery := ""
	    cQuery := " DELETE FROM " + RetSqlName("UP3")
		cQuery += " WHERE D_E_L_E_T_ <> '*' "
		cQuery += " AND UP3_FILIAL = '"+xFilial("UP2")+"'"
		cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
		cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
		cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
		cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
		cQuery += " AND UP3_SEQ = '"+cSeq+"'"  //sequencia
		cQuery += " AND UP3_ID_PAI = '"+cValToChar(UP2->(Recno()))+"'"
		TcSqlExec(cQuery)
		
		VerTabela("TRB22DT")
		
		//carrega o acols
		aCols := {}
		CgaCols(@aCols)

		oGetDados:Refresh()
	Endif	
Return

Static Function SX1_022(cPergunta)
Local aArea	:=	GetArea()
Local nI

//Limpa o conteudo das perguntas ja gravado
DbSelectArea("SX1")
SX1->(DbSetOrder(1))
For nI := 1 To 34
	If DbSeek(PADR(cPergunta,10)+PADL(cValtoChar(nI),2,"0"))
		RecLock("SX1",.F.)
		SX1->X1_CNT01 := ""
		SX1->(MsUnlock())
	EndIf
Next
DbCloseArea("SX1")

PutSx1MA(cPergunta,"01","Quantidade:" ," "," ","mv_ch01","N",TAMSX3("UP3_QUANT")[1],TAMSX3("UP3_QUANT")[2],0,"G","","","","","mv_par01","","","","","","","","","","","","",""," "," "," ",{"Quantidade"},{"Quantidade"},{"Quantidade"})
RestArea(aArea)
Return

Static Function SX1_22S(cPergunta)
Local aArea	:=	GetArea()
Local nI

//Limpa o conteudo das perguntas ja gravado
DbSelectArea("SX1")
SX1->(DbSetOrder(1))
For nI := 1 To 34
	If DbSeek(PADR(cPergunta,10)+PADL(cValtoChar(nI),2,"0"))
		RecLock("SX1",.F.)
		SX1->X1_CNT01 := ""
		SX1->(MsUnlock())
	EndIf
Next
DbCloseArea("SX1")

PutSx1MA(cPergunta,"01","Sequencia:" ," "," ","mv_ch01","C",TAMSX3("UP3_SEQ")[1],0,0,"G","","","","","mv_par01","","","","","","","","","","","","",""," "," "," ",{"Sequencia"},{"Sequencia"},{"Sequencia"})
RestArea(aArea)
Return

Static Function Confere()
Local aAreaUP3	  := {}
Local lSemPedido  := .F.	
Local cQuery      := ""
Local cRetorno    := ""
    
    If !MsgYesNo("Deseja encaminhar para a conferência física?",cCadastro)  
    	Return()
    Endif
    
    If lCRxPed   //Se encaminha para o fisico se tiver algum item criticado  
		cQuery := ""
		cQuery := " SELECT UP3_DOC FROM  " + RetSqlName("UP3")
		cQuery += " WHERE D_E_L_E_T_ <> '*' "
		cQuery += " AND UP3_FILIAL = '"+xFilial("UP2")+"'"
		cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
		cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
		cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
		cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
		cQuery += " AND UP3_ID_PAI = '"+cValToChar(UP2->(Recno()))+"'"
		cQuery += " AND UP3_STCRIT = 'S'"
		
		VerTabela("TRB22DT")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRB22DT",.T.,.T.)

    	If !Empty(TRB22DT->UP3_DOC)
    		MsgAlert("Existe(m) item(s) criticado(s). Não é possível encaminhar para a conferência física.",cTitulo)
			Return()
    	Endif
    Endif
    
    If lPCxPed   //Se todos os itens tem que ter pedido de compra
		cQuery := ""
		cQuery := " SELECT UP3_DOC FROM  " + RetSqlName("UP3")
		cQuery += " WHERE D_E_L_E_T_ <> '*' "
		cQuery += " AND UP3_FILIAL = '"+xFilial("UP2")+"'"
		cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
		cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
		cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
		cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
		cQuery += " AND UP3_ID_PAI = '"+cValToChar(UP2->(Recno()))+"'"
		cQuery += " AND UP3_PEDIDO = ' '"
		
		VerTabela("TRB22DT")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRB22DT",.T.,.T.)

    	If !Empty(TRB22DT->UP3_DOC)
    		MsgAlert("Todos os iten(s) tem que ter pedido de compra. Não é possível encaminhar para a conferência física.",cTitulo)
			Return()
    	Endif
    Endif
	
	RecLock("UP2",.F.)
	UP2->UP2_STATUS := "F"         //Envia documento para conferencia do fisico
	UP2->UP2_USRCOM	:= RetCodUsr()
	UP2->UP2_DATCOM	:= Date()
	UP2->UP2_HORACO	:= Time()
   	UP2->(MsUnlock())
Return


User Function EXTMA05()         
	Local cXML    := UP2_ARQXML	
	Local nCount  := 0
	Local cDir    := cGetFile('','Escolha o Diretorio', 0, Iif( IsSrvUnix(), "/SPOOL/","\SPOOL\"), .T.,GETF_RETDIRECTORY+GETF_LOCALHARD+GETF_NETWORKDRIVE+GETF_LOCALFLOPPY,.F. )
	Local nHandle := FCreate(cDir+Alltrim(UP2->UP2_CHVNFE)+'.xml')

	If nHandle < 0
		MsgAlert("Erro durante criação do arquivo.")
	ElseIf !Empty(cDir)
		FWrite(nHandle,cXML)
		FClose(nHandle)
		MsgAlert("Arquivo gerado com sucesso no diretório: " +Chr(13)+Chr(10)+ cDir+Alltrim(UP2->UP2_CHVNFE)+'.xml')
	EndIf
Return 


User Function CANMA05(cAlias, nReg,nOpc)
	Local	aSize		:= {}
	Local	aInfo		:= {}
	Local	aPosObj		:= {}
	Local	aObjects	:= {}
	Local	cGetDocume	:= UP2->UP2_DOC
	Local	cGetSerie	:= UP2->UP2_SERIE
	Local	cGetFornec	:= UP2->UP2_FORNEC
	Local	cGetLoja	:= UP2->UP2_LOJA
	Local	cGetNomFor	:= POSICIONE("SA2",1,xFilial("SA2")+cGetFornec+cGetLoja,"A2_NOME")
	Local	cGetMotivo	:= CriaVar("UP2_MOTIVO")
	Local	cMotivo		:= ""
	Local	oDlg		:= {}
	Local	oBtnConfir	:= {}
	Local	oBtnCancel	:= {}
	Local	lRet		:= .F.
	
	DbSelectArea("UP2")
	If UP2->UP2_STATUS == "P"
		If !MsgYesNo("NF/CTE já integrado ao Protheus. Confirma cancelamento?")
			Return
		EndIf
	Endif
	
	If UP2->UP2_REPROV == "S"
		If MsgYesNo("NF/CTE já cancelado. Deseja estornar o cancelamento?")
			RecLock("UP2",.F.)
	
			UP2->UP2_REPROV	:= "N"
			UP2->UP2_MOTIVO	:= ""
			UP2->UP2_USRREP	:= ""
			UP2->UP2_DTREPR	:= ctod("")      
			UP2->UP2_HORARP	:= ""
			
			//Caso tenha sido processada, volto status de processamento
			If UP2_PROCES == 'S'
				UP2_PROCES := 'N'
			EndIf
		
			UP2->(MsUnlock())
		Endif	

		Return()
	EndIf

	//Definicao do tamanho do dialogo e dos objetos
	aSize := MsAdvSize(.F./* lEnchoice */,.F.)
	aInfo := { aSize[1], aSize[2], aSize[3], aSize[4], 5, 5, 5, 5}
	AAdd( aObjects, { 100, 040, .T., .T.,	.T. } )
	AAdd( aObjects, { 100, 050, .T., .T.,	.T. } )	
	AAdd( aObjects, { 100, 010, .T., .T.,	.F. } )	
	aPosObj := MsObjSize( aInfo, aObjects, .T. ) 
	
	oDlg	:= MsDialog():New(aSize[7],0,aSize[6],aSize[5],cTitulo,,,,,/*nClrText*/,/*nClrBack*/,,, .T.,,,,,)
	oPanel1		:= TPanel():New(aPosObj[1,1],aPosObj[1,2],/*cText*/,oDlg,/*oFont*/,.T./*lCentered*/,/*uParam7*/,/*nClrText*/,/*nClrBack*/,aPosObj[1,3]/*nWidth*/ ,aPosObj[1,4]/*nHeight*/,.T./*lLowered*/,.F./*lRaised*/ )
	
	oLblDocume	:= TSay():New(C(010),C(010),{||"Documento:   "},oPanel1,/*cPicture*/,/*oFont*/,,,,.T.,CLR_BLUE/*nClrText*/,/*nClrBack*/,/*nWidth*/,/*nHeight*/,,,,,,/*lHTML*/)
	oGetDocume	:= TGet():New(C(017),C(010),{|| cGetDocume}/*bSetGet*/,oPanel1/*oWnd*/,C(020)/*nWidth*/,C(008)/*nHeight*/,/*cPict*/,/*bValid*/,/*nClrFore*/,/*nClrBack*/,/*oFont*/,/*uParam12*/,/*uParam13*/,.T./*lPixel*/,/*uParam15*/,/*uParam16*/,/*bWhen*/,/*uParam18*/,;
	/*uParam19*/,/*bChange*/,.T./*lReadOnly*/,/*lPassword*/,/*uParam23*/,cGetDocume/*cReadVar*/,/*uParam25*/,/*uParam26*/,/*uParam27*/,/*lHasButton*/,/*lNoButton*/,/*cLabelText*/,/*nLabelPos*/,/*oLabelFont*/,/*nLabelColor*/)
	
	oLblSerie	:= TSay():New(C(010),C(080),{||"Serie:   "},oPanel1,/*cPicture*/,/*oFont*/,,,,.T.,CLR_BLUE/*nClrText*/,/*nClrBack*/,/*nWidth*/,/*nHeight*/,,,,,,/*lHTML*/)
	oGetSerie	:= TGet():New(C(017),C(080),{|| cGetSerie}/*bSetGet*/,oPanel1/*oWnd*/,C(015)/*nWidth*/,C(008)/*nHeight*/,/*cPict*/,/*bValid*/,/*nClrFore*/,/*nClrBack*/,/*oFont*/,/*uParam12*/,/*uParam13*/,.T./*lPixel*/,/*uParam15*/,/*uParam16*/,/*bWhen*/,/*uParam18*/,;
	/*uParam19*/,/*bChange*/,.T./*lReadOnly*/,/*lPassword*/,/*uParam23*/,cGetSerie/*cReadVar*/,/*uParam25*/,/*uParam26*/,/*uParam27*/,/*lHasButton*/,/*lNoButton*/,/*cLabelText*/,/*nLabelPos*/,/*oLabelFont*/,/*nLabelColor*/)
	
	oLblFornec	:= TSay():New(C(030),C(010),{||"Fornecedor:"},oPanel1,/*cPicture*/,/*oFont*/,,,,.T.,CLR_BLUE/*nClrText*/,/*nClrBack*/,/*nWidth*/,/*nHeight*/,,,,,,/*lHTML*/)
	oGetFornec	:= TGet():New(C(037),C(010),{|| cGetFornec }/*bSetGet*/,oPanel1/*oWnd*/,C(020)/*nWidth*/,C(008)/*nHeight*/,"@!"/*cPict*/,/*bValid*/,/*nClrFore*/,/*nClrBack*/,/*oFont*/,/*uParam12*/,/*uParam13*/,.T./*lPixel*/,/*uParam15*/,/*uParam16*/,/*bWhen*/,/*uParam18*/,;
	/*uParam19*/,/*bChange*/,.T./*lReadOnly*/,/*lPassword*/,/*uParam23*/,cGetFornec/*cReadVar*/,/*uParam25*/,/*uParam26*/,/*uParam27*/,/*lHasButton*/,/*lNoButton*/,/*cLabelText*/,/*nLabelPos*/,/*oLabelFont*/,/*nLabelColor*/)
	
	oLblLoja	:= TSay():New(C(030),C(080),{||"Loja:"},oPanel1,/*cPicture*/,/*oFont*/,,,,.T.,CLR_BLUE/*nClrText*/,/*nClrBack*/,/*nWidth*/,/*nHeight*/,,,,,,/*lHTML*/)
	oGetLoja	:= TGet():New(C(037),C(080),{|| cGetLoja }/*bSetGet*/,oPanel1/*oWnd*/,C(015)/*nWidth*/,C(008)/*nHeight*/,"@!"/*cPict*/,/*bValid*/,/*nClrFore*/,/*nClrBack*/,/*oFont*/,/*uParam12*/,/*uParam13*/,.T./*lPixel*/,/*uParam15*/,/*uParam16*/,/*bWhen*/,/*uParam18*/,;
	/*uParam19*/,/*bChange*/,.T./*lReadOnly*/,/*lPassword*/,/*uParam23*/,cGetLoja/*cReadVar*/,/*uParam25*/,/*uParam26*/,/*uParam27*/,/*lHasButton*/,/*lNoButton*/,/*cLabelText*/,/*nLabelPos*/,/*oLabelFont*/,/*nLabelColor*/)
	
	oLblNome	:= TSay():New(C(030),C(120),{||"Nome Fornecedor:"},oPanel1,/*cPicture*/,/*oFont*/,,,,.T.,CLR_BLUE/*nClrText*/,/*nClrBack*/,/*nWidth*/,/*nHeight*/,,,,,,/*lHTML*/)
	oGetNome	:= TGet():New(C(037),C(120),{|| cGetNomFor}/*bSetGet*/,oPanel1/*oWnd*/,C(100)/*nWidth*/,C(008)/*nHeight*/,"@!"/*cPict*/,/*bValid*/,/*nClrFore*/,/*nClrBack*/,/*oFont*/,/*uParam12*/,/*uParam13*/,.T./*lPixel*/,/*uParam15*/,/*uParam16*/,/*bWhen*/,/*uParam18*/,;
	/*uParam19*/,/*bChange*/,.T./*lReadOnly*/,/*lPassword*/,/*uParam23*/,cGetNomFor/*cReadVar*/,/*uParam25*/,/*uParam26*/,/*uParam27*/,/*lHasButton*/,/*lNoButton*/,/*cLabelText*/,/*nLabelPos*/,/*oLabelFont*/,/*nLabelColor*/)
	
	oLblMotivo	:= TSay():New(C(050),C(010),{||"Informe o motivo do cancelamento"},oPanel1,/*cPicture*/,/*oFont*/,,,,.T.,CLR_BLUE/*nClrText*/,/*nClrBack*/,/*nWidth*/,/*nHeight*/,,,,,,/*lHTML*/)
	oGetMotivo	:= TGet():New(C(057),C(010),{|u| If(PCount()>0,cGetMotivo:=u,cGetMotivo)}/*bSetGet*/,oPanel1/*oWnd*/,C(250)/*nWidth*/,C(008)/*nHeight*/,"@!"/*cPict*/,/*bValid*/,/*nClrFore*/,/*nClrBack*/,/*oFont*/,/*uParam12*/,/*uParam13*/,.T./*lPixel*/,/*uParam15*/,/*uParam16*/,/*bWhen*/,/*uParam18*/,;
	/*uParam19*/,/*bChange*/,.F./*lReadOnly*/,/*lPassword*/,/*uParam23*/,cGetMotivo/*cReadVar*/,/*uParam25*/,/*uParam26*/,/*uParam27*/,/*lHasButton*/,/*lNoButton*/,/*cLabelText*/,/*nLabelPos*/,/*oLabelFont*/,/*nLabelColor*/)

	oPanel3		:= TPanel():New(aPosObj[3,1],aPosObj[3,2],/*cText*/,oDlg,/*oFont*/,.T./*lCentered*/,/*uParam7*/,/*nClrText*/,/*nClrBack*/,aPosObj[2,3]/*nWidth*/ ,aPosObj[2,4]/*nHeight*/,.T./*lLowered*/,.T./*lRaised */ )
	//Cria Botoes
	oBtnConfir	:= TButton():New(c(010),C(010),"Confirmar",oPanel3,{|| If(!Empty(cGetMotivo),(cMotivo := AllTrim(cGetMotivo),lRet:= .T., oDlg:End()),MsgAlert("Obrigatorio informar motivo do cancelamento")) },C(030),C(015),,/*oFont*/,,.T.,,,,/*bWhen*/,,)
	oBtnCancel	:= TButton():New(c(010),C(045),"Cancelar" ,oPanel3,{|| lRet:= .F., oDlg:End()},C(030),C(015),,/*oFont*/,,.T.,,,,/*bWhen*/,,)

	oDlg:Activate()
	
	If lRet
		RecLock("UP2",.F.)
	
		UP2->UP2_REPROV	:= "S"
		UP2->UP2_MOTIVO	:= cMotivo
		UP2->UP2_USRREP	:= RetCodUsr()
		UP2->UP2_DTREPR	:= Date()
		UP2->UP2_HORARP	:= Time()
			
		//Caso tenha sido processada, volto status de processamento
		If UP2_PROCES == 'S'
			UP2_PROCES := 'N'
		EndIf
	
		UP2->(MsUnlock())
		MsgAlert("Processo realizado com sucesso")
	EndIF
Return

User Function Prt05Ex(cAlias, nReg,nOpc)
	Local cDocumento  := ""
	Local cSerie      := ""
	Local cFornecedor := ""
	Local cLoja       := ""
	Local cRecnoPai   := ""
	
	Private	lMsErroAuto := .F.
	Private	lMsHelpAuto := .F.
	
	DbSelectArea("UP2")
	cDocumento	:= UP2->UP2_DOC
	cSerie		:= UP2->UP2_SERIE
	cFornecedor := UP2->UP2_FORNEC
	cLoja		:= UP2->UP2_LOJA
	cLoja		:= UP2->UP2_LOJA
	cRecnoPai	:= UP2->(Recno())

	//Monto Cabecalho
	aCabec	:= {}
	aadd(aCabec,{"F1_TIPO"   ,UP2->UP2_TIPO,Nil,Nil})
	aadd(aCabec,{"F1_FORMUL" ,UP2->UP2_FORMUL,Nil,Nil})
	aadd(aCabec,{"F1_DOC"    ,UP2->UP2_DOC,Nil,Nil})
	aadd(aCabec,{"F1_SERIE"  ,UP2->UP2_SERIE,Nil,Nil})
	aadd(aCabec,{"F1_CHVNFE" ,UP2->UP2_CHVNFE,NIL})
	
	IF !Empty(UP2->UP2_ESPEC1)
		aadd(aCabec,{"F1_ESPECI1",AllTrim(UP2->UP2_ESPEC1),NIL})
	Endif
	
	IF UP2->UP2_VOLUME > 0
		aadd(aCabec,{"F1_VOLUME1",UP2->UP2_VOLUME,NIL})
	Endif
	
	IF UP2->UP2_PLIQUI > 0
		aadd(aCabec,{"F1_PLIQUI",UP2->UP2_PLIQUI,NIL})
	Endif
	
	IF UP2->UP2_PBRUTO > 0
		aadd(aCabec,{"F1_PBRUTO",UP2->UP2_PBRUTO,NIL})
	Endif
	
	IF !Empty(UP2->UP2_TRANSP)
	  	SA4->(dbSetOrder(3) )
		
		IF	SA4->(dbSeek(xFilial("SA4")+AllTrim(UP2->UP2_TRANSP)))
	  		aadd(aCabec,{"F1_TRANSP",SA4->A4_COD,NIL})
		Endif
	Endif
	
	aadd(aCabec,{"F1_EMISSAO",UP2->UP2_EMISSA,Nil,Nil})
	aadd(aCabec,{"F1_FORNECE",UP2->UP2_FORNEC,Nil,Nil})
	aadd(aCabec,{"F1_LOJA"   ,UP2->UP2_LOJA,Nil,Nil})
	aadd(aCabec,{"F1_ESPECIE",UP2->UP2_ESPECI,Nil,Nil})
	
	IF UP2->UP2_VFRETE > 0
		aadd(aCabec,{"F1_FRETE",UP2->UP2_VFRETE,Nil,NIL})
	Endif
	   
	IF UP2->UP2_VOUTRO > 0
		aadd(aCabec,{"F1_DESPESA",UP2->UP2_VOUTRO,Nil,NIL})
	Endif

	IF UP2->UP2_VDESC > 0
		aadd(aCabec,{"F1_DESCONT",UP2->UP2_VDESC,Nil,NIL})
	Endif

	IF UP2->UP2_VSEGUR > 0
		aadd(aCabec,{"F1_SEGURO",UP2->UP2_VSEGUR,Nil,NIL})
	Endif

	//Monto Itens
	aItens	:= {}
	DbSelectArea("UP3")
	dbSetOrder(2)
	UP3->(DbGoTop())
	DbSeek(xFilial("UP3")+cDocumento+cSerie+cFornecedor+cLoja)
		Do While !UP3->(Eof()) .And. UP3->UP3_DOC==cDocumento .And. UP3->UP3_SERIE==cSerie
			If UP3->UP3_DOC==cDocumento .And. UP3->UP3_SERIE==cSerie .And. cRecnoPai==UP3->UP3_ID_PAI
				aLinha  := {}
				
				aadd(aLinha,{"D1_COD",UP3->UP3_COD,Nil,Nil})
				aadd(aLinha,{"D1_QUANT",UP3->UP3_QUANT,Nil,Nil})
				aadd(aLinha,{"D1_VUNIT",UP3->UP3_VUNIT,Nil,Nil})
				aadd(aLinha,{"D1_TOTAL",UP3->UP3_TOTAL,Nil,Nil})
				aadd(aLinha,{"D1_ITEM",PadL(Alltrim(UP3->UP3_SEQ),TamSX3("D1_ITEM")[1],"0"),Nil,Nil})
				
				If UP3->UP3_VALDES > 0
					aadd(aLinha,{"D1_VALDESC",UP3->UP3_VALDES,Nil,Nil})
				Endif
				
				If UP3->UP3_PICMS > 0
					aadd(aLinha,{"D1_PICM",UP3->UP3_PICMS,Nil,Nil})
				Endif
					
				If UP3->UP3_VICMS > 0
					aadd(aLinha,{"D1_VALICM",UP3->UP3_VICMS,Nil,Nil})
				Endif

				If UP3->UP3_PIPI > 0
					aadd(aLinha,{"D1_IPI",UP3->UP3_PIPI,Nil,Nil})
				Endif
					
				If UP3->UP3_VIPI > 0
					aadd(aLinha,{"D1_VALIPI",UP3->UP3_VIPI,Nil,Nil})
				Endif
                	
				If UP3->UP3_PPIS > 0
					aadd(aLinha,{"D1_ALQPIS",UP3->UP3_PPIS,Nil,Nil})
				Endif
                	
				If UP3->UP3_VPIS > 0
					aadd(aLinha,{"D1_VALPIS",UP3->UP3_VPIS,Nil,Nil})
				Endif
                	
				If UP3->UP3_PCOFIN > 0
					aadd(aLinha,{"D1_ALQCOF",UP3->UP3_PCOFIN,Nil,Nil})
				Endif
                	
				If UP3->UP3_VCOFIN > 0
					aadd(aLinha,{"D1_VALCOF",UP3->UP3_VCOFIN,Nil,Nil})
				Endif
				
				aadd(aItens,aLinha)
			EndIf
			UP3->(dbSkip())
		Enddo
	
	Begin Transaction
		If UP2->UP2_TIPO == 'R'.or. UP2->UP2_TIPO == 'E'
			aCabec[Ascan(aCabec,{|x| Alltrim(x[1])=="F1_TIPO"})][2]:='N' //Tipo da NF "N - Normal",obrigatório a informação do fornecedor.
		EndIf
		MSExecAuto({ |x,y,z| Mata140(x,y,z)},aCabec,aItens,3)
	End Transaction
	
	If lMsErroAuto
		lRet := .F.
		MsgAlert("Erro no processo")
		MostraErro()
	Else
		RecLock("UP2",.F.)
		UP2->UP2_STATUS := "P" 
		UP2->UP2_USREXP	:= RetCodUsr()
		UP2->UP2_DATEXP	:= Date()
		UP2->UP2_HORAEX	:= Time()
		UP2->UP2_PROCES := "S"
		UP2->(MsUnlock())
		
		//atuazação de informações que o execauto nao grava
		DbSelectArea("UP3")
		dbSetOrder(2)
		UP3->(DbGoTop())
		DbSeek(xFilial("UP3")+cDocumento+cSerie+cFornecedor+cLoja)
			//Garanto que o registro dos itens do XML é do mesmo arquivo xml sendo atualizado
			Do While !UP3->(Eof()) .And. UP3->UP3_DOC==cDocumento .And. UP3->UP3_SERIE==cSerie
				If UP3->UP3_DOC==cDocumento .And. UP3->UP3_SERIE==cSerie .And. cRecnoPai==UP3->UP3_ID_PAI 
					
					//segunda unidade de medida
					SB1->(dbSetOrder(1),dbSeek(xFilial("SB1")+UP3->UP3_COD))
					If !Empty(SB1->B1_SEGUM)
						cQuery := MtQryD1(cFornecedor,cLoja,cDocumento,cSerie,PadL(Alltrim(UP3->UP3_SEQ),TamSX3("D1_ITEM")[1],"0"))
						VerTabela("TRBSD1")
						dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBSD1",.T.,.T.)
	
						DbSelectArea("SD1")
						SD1->(DbGoTo(TRBSD1->R_E_C_N_O_))
						RecLock("SD1",.F.)
					
						If Upper(Alltrim(UP3->UP3_UNTRIB))==Upper(Alltrim(SB1->B1_UM))
							SD1->D1_QTSEGUM := iIf(SB1->B1_TIPCONV=='M',SD1->D1_QUANT * SB1->B1_CONV,SD1->D1_QUANT / SB1->B1_CONV)
					    ElseIf Upper(Alltrim(UP3->UP3_UNTRIB))==Upper(Alltrim(SB1->B1_SEGUM))
							SD1->D1_QTSEGUM := SD1->D1_QUANT
							SD1->D1_QUANT   := iIf(SB1->B1_TIPCONV=='M', SD1->D1_QTSEGUM / SB1->B1_CONV, SD1->D1_QTSEGUM * SB1->B1_CONV)
							SD1->D1_VUNIT   := SD1->D1_TOTAL / SD1->D1_QUANT
					    EndIf
					    SD1->(MsUnlock())
					    VerTabela("TRBSD1")
					EndIf
					
					//se e obrigatorio ter pc
					If lCpoxPed .And. !Empty(UP3->UP3_PEDIDO) .And. !Empty(UP3->UP3_ITEMPC)
					
						cQuery := MtQryD1(cFornecedor,cLoja,cDocumento,cSerie,PadL(Alltrim(UP3->UP3_SEQ),TamSX3("D1_ITEM")[1],"0"))
						VerTabela("TRBSD1")
						dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRBSD1",.T.,.T.)
	
						DbSelectArea("SD1")
						SD1->(DbGoTo(TRBSD1->R_E_C_N_O_))
						RecLock("SD1",.F.)
					
						SD1->D1_PEDIDO  := UP3->UP3_PEDIDO
   						SD1->D1_ITEMPC  := UP3->UP3_ITEMPC
   						SD1->D1_CLASFIS := UP3->UP3_CLASFI
						SD1->(MsUnlock())
						VerTabela("TRBSD1")
					EndIf
				EndIf
				UP3->(dbSkip())
			Enddo
			
		lRet := .T.
		If nOpc = 3
			MsgAlert("Processo realizado com sucesso")
		Endif	
	EndIf
Return lRet

Static Function MtQryD1(cFor,cLj,cDoc,cSer,cItem)
	Local cQry := "" 
						
	cQry := ""
	cQry += " SELECT R_E_C_N_O_ "
	cQry += " FROM " + RetSQLName("SD1") + " SD1"
	cQry += " WHERE SD1.D1_FILIAL = '" + xFilial("SD1") + "'"
	cQry += " AND SD1.D_E_L_E_T_ <> '*' "
	cQry += " AND SD1.D1_FORNECE = '" + cFor  +"' "
	cQry += " AND SD1.D1_LOJA = '"    + cLj   +"' "
	cQry += " AND SD1.D1_DOC = '"     + cDoc  +"' "
	cQry += " AND SD1.D1_SERIE = '"   + cSer  +"' "
	cQry += " AND SD1.D1_ITEM = '"    + cItem +"' "
Return(cQry)


Static Function VerTabela(tab)
	IIf(Select(tab) > 0, (tab)->(dbCloseArea()), Nil)
Return


Static Function PutSx1MA(cGrupo,cOrdem,cPergunt,cPerSpa,cPerEng,cVar,;
	cTipo ,nTamanho,nDecimal,nPresel,cGSC,cValid,;
	cF3, cGrpSxg,cPyme,;
	cVar01,cDef01,cDefSpa1,cDefEng1,cCnt01,;
	cDef02,cDefSpa2,cDefEng2,;
	cDef03,cDefSpa3,cDefEng3,;
	cDef04,cDefSpa4,cDefEng4,;
	cDef05,cDefSpa5,cDefEng5,;
	aHelpPor,aHelpEng,aHelpSpa,cHelp)

LOCAL aArea := GetArea()
Local cKey
Local lPort := .f.
Local lSpa  := .f.
Local lIngl := .f. 

cKey  := "P." + AllTrim( cGrupo ) + AllTrim( cOrdem ) + "."

cPyme    := Iif( cPyme 		== Nil, " ", cPyme		)
cF3      := Iif( cF3 		== NIl, " ", cF3		)
cGrpSxg  := Iif( cGrpSxg	== Nil, " ", cGrpSxg	)
cCnt01   := Iif( cCnt01		== Nil, "" , cCnt01 	)
cHelp	 := Iif( cHelp		== Nil, "" , cHelp		)

dbSelectArea( "SX1" )
dbSetOrder( 1 )

cGrupo := PadR( cGrupo , Len( SX1->X1_GRUPO ) , " " )

If !( DbSeek( cGrupo + cOrdem ))

    cPergunt:= If(! "?" $ cPergunt .And. ! Empty(cPergunt),Alltrim(cPergunt)+" ?",cPergunt)
	cPerSpa	:= If(! "?" $ cPerSpa  .And. ! Empty(cPerSpa) ,Alltrim(cPerSpa) +" ?",cPerSpa)
	cPerEng	:= If(! "?" $ cPerEng  .And. ! Empty(cPerEng) ,Alltrim(cPerEng) +" ?",cPerEng)

	Reclock( "SX1" , .T. )

	Replace X1_GRUPO   With cGrupo
	Replace X1_ORDEM   With cOrdem
	Replace X1_PERGUNT With cPergunt
	Replace X1_PERSPA  With cPerSpa
	Replace X1_PERENG  With cPerEng
	Replace X1_VARIAVL With cVar
	Replace X1_TIPO    With cTipo
	Replace X1_TAMANHO With nTamanho
	Replace X1_DECIMAL With nDecimal
	Replace X1_PRESEL  With nPresel
	Replace X1_GSC     With cGSC
	Replace X1_VALID   With cValid

	Replace X1_VAR01   With cVar01

	Replace X1_F3      With cF3
	Replace X1_GRPSXG  With cGrpSxg

	If Fieldpos("X1_PYME") > 0
		If cPyme != Nil
			Replace X1_PYME With cPyme
		Endif
	Endif

	Replace X1_CNT01   With cCnt01
	If cGSC == "C"			// Mult Escolha
		Replace X1_DEF01   With cDef01
		Replace X1_DEFSPA1 With cDefSpa1
		Replace X1_DEFENG1 With cDefEng1

		Replace X1_DEF02   With cDef02
		Replace X1_DEFSPA2 With cDefSpa2
		Replace X1_DEFENG2 With cDefEng2

		Replace X1_DEF03   With cDef03
		Replace X1_DEFSPA3 With cDefSpa3
		Replace X1_DEFENG3 With cDefEng3

		Replace X1_DEF04   With cDef04
		Replace X1_DEFSPA4 With cDefSpa4
		Replace X1_DEFENG4 With cDefEng4

		Replace X1_DEF05   With cDef05
		Replace X1_DEFSPA5 With cDefSpa5
		Replace X1_DEFENG5 With cDefEng5
	Endif

	Replace X1_HELP  With cHelp

	PutSX1Help(cKey,aHelpPor,aHelpEng,aHelpSpa)

	MsUnlock()
Else

   lPort := ! "?" $ X1_PERGUNT .And. ! Empty(SX1->X1_PERGUNT)
   lSpa  := ! "?" $ X1_PERSPA  .And. ! Empty(SX1->X1_PERSPA)
   lIngl := ! "?" $ X1_PERENG  .And. ! Empty(SX1->X1_PERENG)

   If lPort .Or. lSpa .Or. lIngl
		RecLock("SX1",.F.)
		If lPort 
         SX1->X1_PERGUNT:= Alltrim(SX1->X1_PERGUNT)+" ?"
		EndIf
		If lSpa 
			SX1->X1_PERSPA := Alltrim(SX1->X1_PERSPA) +" ?"
		EndIf
		If lIngl
			SX1->X1_PERENG := Alltrim(SX1->X1_PERENG) +" ?"
		EndIf
		SX1->(MsUnLock())
	EndIf
Endif

RestArea( aArea )
Return 


Static Function PedCom()
Local oAssocia
Local oFechar
Local oGroup1
Local oGroup2
Local oLimpar
Static oDlg  
        
//vejo se não eh informação de cliente: devolucao ou beneficiamente
If UP2->UP2_TIPO = 'D' .Or. UP2->UP2_TIPO = 'B' 
	MsgAlert("Para NFE de cliente não é possível associar pedido de compra.",cTitulo)
	Return()
Endif

aColsExD := {}
aColsEx  := {}

DEFINE MSDIALOG oDlg TITLE "Associação de Pedidos de Compra" FROM 000, 000  TO 400, 1050 COLORS 0, 16777215 PIXEL

    @ 112, 000 GROUP oGroup2 TO 450, 600 PROMPT "Pedido(s) de Compra Disponível(s)" OF oDlg COLOR 0, 16777215 PIXEL
    XML05DSP()
    
    @ 003, 000 GROUP oGroup1 TO 450, 600 PROMPT "Item(s) da NFE" OF oDlg COLOR 0, 16777215 PIXEL
    XML05IT()

    @ 102, 200 BUTTON oAssocia PROMPT "Associa PC" SIZE 037, 012 OF oDlg ACTION u_XML5AC() PIXEL
    @ 102, 270 BUTTON oLimpar  PROMPT "Limpa PC"   SIZE 037, 012 OF oDlg ACTION u_XML5LP() PIXEL
    @ 185, 240 BUTTON oFechar  PROMPT "Confirmar"  SIZE 037, 012 OF oDlg ACTION {u_XML5CF(), oDlg:End()} PIXEL

ACTIVATE MSDIALOG oDlg CENTERED                            
Return
                    

User Function XML5LP()
	aColsEx[oMSNewGe1:oBrowse:nAt,5] := ""
	aColsEx[oMSNewGe1:oBrowse:nAt,6] := ""

	oMSNewGe1:SetArray(aColsEx)
	oMSNewGe1:Refresh()
Return  


User Function XML5AC()
	If !Empty(aColsExD)
		aColsEx[oMSNewGe1:oBrowse:nAt,5] := aColsExD[oMSNewGe2:oBrowse:nAt,1] 
		aColsEx[oMSNewGe1:oBrowse:nAt,6] := aColsExD[oMSNewGe2:oBrowse:nAt,2] 

		oMSNewGe1:SetArray(aColsEx)
		oMSNewGe1:Refresh()
	Endif		
Return  
                                                                                         

User Function XML5CF()
Local nX       := 0	
Local nPosPed  := Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_PEDIDO"})
Local nPosItem := Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_ITEMPC"})
Local nPosCrit := Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_CRITIC"})
Local cQuery   := ""
Local cDesCrit := ""
Local cSTCrit  := ""
Local cPed     := ""
Local cItemPed := ""
Local nPrPC    := 0
	
	If MsgYesNo("Confirma o(s) dados?",cTitulo)
		For nX:= 1 to Len(aColsEx)
	    	If !Empty(aColsEx[nX,5])
	    		//busco o preco do pedido de compra
	    		cQuery := ""
				cQuery := " SELECT C7_PRECO "
				cQuery += " FROM " + RetSqlName("SC7")
				cQuery += " WHERE D_E_L_E_T_ <> '*' "
				cQuery += " AND C7_FILIAL = '"+xFilial("SC7")+"'"
				cQuery += " AND C7_NUM = '"+aColsEx[nX,5]+"'"
				cQuery += " AND C7_ITEM = '"+aColsEx[nX,6]+"'"
                
                VerTabela("XML05PR")
                dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05PR",.T.,.T.)
				nPrPC := XML05PR->C7_PRECO
	    		
	    		If aColsEx[nX,7] <> nPrPC  //caso os precos forem diferentes
	    			If lTolera  //se o parametro de tolerancia esta ativo e se tem registro
	    				If TolPrc(UP2->UP2_FORNEC,UP2->UP2_LOJA,Posicione("SB1",1,xFilial("SB1")+aColsEx[nX,2],"B1_GRUPO"),aColsEx[nX,2],aColsEx[nX,7],nPrPC)
	    					cDesCrit := "Preço XML: " + cValTochar(aColsEx[nX,7]) + " - Preço PC: " + cValTochar(nPrPC) 
							cSTCrit  := "S"
	    				Else
			    			cDesCrit := " "
							cSTCrit  := "N"
	    				Endif
	    			Else
		    			cDesCrit := "Preço XML: " + cValTochar(aColsEx[nX,7]) + " - Preço PC: " + cValTochar(nPrPC) 
						cSTCrit  := "S"
					Endif
                Else
	    			cDesCrit := " "
					cSTCrit  := "N"
                Endif
                
                cPed     := aColsEx[nX,5]
                cItemPed := aColsEx[nX,6]
	    	Else
    			cDesCrit := " "
				cSTCrit  := "N"
                cPed     := " "
                cItemPed := " "
	    	Endif

	    	cQuery := ""
            cQuery := " UPDATE " + RetSqlName("UP3")
            cQuery += " SET UP3_PEDIDO = '"+cPed+"'"
            cQuery += " ,UP3_ITEMPC = '"+cItemPed+"'"
            cQuery += " ,UP3_CRITIC = '"+cDesCrit+"'"
            cQuery += " ,UP3_STCRIT = '"+cSTCrit+"'"
			cQuery += " WHERE D_E_L_E_T_ <> '*' "
			cQuery += " AND UP3_FILIAL = '"+xFilial("UP2")+"'"
			cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
			cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
			cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
			cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
			cQuery += " AND UP3_SEQ = '"+aColsEx[nX,1]+"'"  
			cQuery += " AND UP3_ID_PAI = '"+cValToChar(UP2->(Recno()))+"'"
			nStatus := TcSqlExec(cQuery)
			
			If (nStatus < 0)
    			Alert("TCSQLError() " + TCSQLError())
			Endif
		Next nX
		
		//carrega o acols atualizado
		aCols := {}
		CgaCols(@aCols)
    Endif
Return                            


Static Function TolPrc(cFornec,cLoja,cGrupo,cProd,nPRXML,nPRPC)
Local lRet := .F.
Local cQueryF      
Local cQuery
      
	cQueryF := ""
	cQueryF := " SELECT AIC_PPRECO "
	cQueryF += " FROM " + RetSqlName("AIC") 
	cQueryF += " WHERE D_E_L_E_T_ <> '*' "
	cQueryF += " AND AIC_FILIAL = '"+xFilial("AIC")+"'"
	    
	//POR PRODUTO E FORNECEDOR
	cQuery := cQueryF + " AND AIC_PRODUT = '"+cProd+"' AND AIC_FORNEC = '"+cFornec+"' AND AIC_LOJA = '"+cLoja+"'"
	VerTabela("XML05TL")
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05TL",.T.,.T.)
    
	If !Empty(XML05TL->AIC_PPRECO)  
		//vejo se está dentro do percentual		
		If nPRXML > (nPRPC + (nPRPC * XML05TL->AIC_PPRECO / 100))
			lRet := .T.
		Endif
	Endif 
		
	If !lRet
		//SOMENTE POR FORNECEDOR            
		cQuery := cQueryF + " AND AIC_PRODUT = ' ' AND AIC_FORNEC = '"+cFornec+"' AND AIC_LOJA = '"+cLoja+"'"
		VerTabela("XML05TL")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05TL",.T.,.T.)
           
        If !Empty(XML05TL->AIC_PPRECO)  
			//vejo se está dentro do percentual		
			If nPRXML > (nPRPC + (nPRPC * XML05TL->AIC_PPRECO / 100))
				lRet := .T.
			Endif
		Endif	
	Endif 
    
	If !lRet
		//SOMENTE POR PRODUTO   
		cQuery := cQueryF + " AND AIC_PRODUT = '"+cProd+"' AND AIC_FORNEC = ' ' AND AIC_LOJA = ' '"
		VerTabela("XML05TL")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05TL",.T.,.T.)
            
        If !Empty(XML05TL->AIC_PPRECO)  
			//vejo se está dentro do percentual		
			If nPRXML > (nPRPC + (nPRPC * XML05TL->AIC_PPRECO / 100))
				lRet := .T.
			Endif
		Endif	
	Endif 
        
	If !lRet
		// SOMENTE POR GRUPO DE PRODUTO 
		cQuery := cQueryF + " AND AIC_GRUPO = '"+cGrupo+"' AND AIC_FORNEC = ' ' AND AIC_LOJA = ' ' AND AIC_PRODUT = ' '"
		VerTabela("XML05TL")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05TL",.T.,.T.)
            
        If !Empty(XML05TL->AIC_PPRECO)  
			//vejo se está dentro do percentual		
			If nPRXML > (nPRPC + (nPRPC * XML05TL->AIC_PPRECO / 100))
				lRet := .T.
			Endif
		Endif	
	Endif 

	VerTabela("XML05TL")
Return(lRet)


Static Function CgaCols(aCCols)
	aCCols:={}
	dbSelectArea("UP3")
	dbSetOrder(1)
	dbSeek(xFilial("UP3")+M->UP2_DOC+M->UP2_SERIE)
	While !eof() .and. UP3->UP3_DOC == M->UP2_DOC
		If  UP3->UP3_ID_PAI == UP2->(Recno())
			AADD(aCCols,Array(nUsado+1))
			For _ni:=1 to nUsado
				If Upper(Alltrim(aHeader[_ni,2])) == "UP3_ID_PAI"
       		        //Quando for o recno, usado para atualizacao
					aCCols[Len(aCCols),_ni] := UP3->(RECNO())
				Else
					aCCols[Len(aCCols),_ni] := FieldGet(FieldPos(aHeader[_ni,2]))
				EndIf
			Next                                                                                       
			aCCols[Len(aCCols),nUsado+1]:=.F.
		EndIf
		dbSkip()
	End
Return()


Static Function XML05IT()
Local nX
Local aHeaderEx    := {}
Local aFieldFill   := {}
Local aFields      := {"UP3_SEQ","UP3_COD","UP3_DESCR","UP3_QUANT","UP3_PEDIDO","UP3_ITEMPC","UP3_VUNIT"}
Local aAlterFields := {}
Local cQuery      
Static oMSNewGe1

//cabecalho
DbSelectArea("SX3")
SX3->(DbSetOrder(2))
For nX := 1 to Len(aFields)
	If SX3->(DbSeek(aFields[nX]))
    	Aadd(aHeaderEx, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
                         SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
    Endif
Next nX

cQuery := ""
cQuery := " SELECT UP3_SEQ,UP3_COD,UP3_DESCR,UP3_QUANT,UP3_PEDIDO,UP3_ITEMPC,UP3_VUNIT,UP3_UNTRIB FROM " + RetSqlName("UP3")
cQuery += " WHERE D_E_L_E_T_ <> '*' "
cQuery += " AND UP3_FILIAL = '"+xFilial("UP3")+"'"
cQuery += " AND UP3_DOC = '"+UP2->UP2_DOC+"'"
cQuery += " AND UP3_SERIE = '"+UP2->UP2_SERIE+"'"
cQuery += " AND UP3_FORNEC = '"+UP2->UP2_FORNEC+"'"
cQuery += " AND UP3_LOJA = '"+UP2->UP2_LOJA+"'"
cQuery += " AND UP3_ID_PAI = "+cValToChar(UP2->(Recno()))
cQuery += " ORDER BY UP3_SEQ"
VerTabela("XML05PC")
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05PC",.T.,.T.)

XML05PC->(DBGOTOP())
Do While !XML05PC->(Eof()) 
	aFieldFill := {}
	
	Aadd(aFieldFill, XML05PC->UP3_SEQ)
	Aadd(aFieldFill, XML05PC->UP3_COD)
	Aadd(aFieldFill, XML05PC->UP3_DESCR)
	Aadd(aFieldFill, XML05PC->UP3_QUANT)
	Aadd(aFieldFill, XML05PC->UP3_PEDIDO)
	Aadd(aFieldFill, XML05PC->UP3_ITEMPC)
	Aadd(aFieldFill, XML05PC->UP3_VUNIT)
	Aadd(aFieldFill, XML05PC->UP3_UNTRIB)
	
	Aadd(aFieldFill, .F.)
	Aadd(aColsEx, aFieldFill)
	
	XML05PC->(dbSkip())
Enddo
VerTabela("XML05PC")

oMSNewGe1 := MsNewGetDados():New( 011, 002, 100, 530, /*GD_INSERT+GD_DELETE+GD_UPDATE*/, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeaderEx, aColsEx,{||ATPC005()} )
Return
                      

Static Function XML05DSP()
Local aFieldFill := {}
Local nX
Local aHeaderEx    := {}
Local aFields      := {"C7_NUM","C7_ITEM","C7_PRODUTO","B1_DESC","C7_QUANT","C7_PRECO"}
Local aAlterFields := {}
Static oMSNewGe2
                         
//campos
DbSelectArea("SX3")
SX3->(DbSetOrder(2))
For nX := 1 to Len(aFields)
	If SX3->(DbSeek(aFields[nX]))
    	Aadd(aHeaderEx, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
                         SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
    Endif
Next nX 

For nX := 1 to Len(aFields)
	If DbSeek(aFields[nX])
    	Aadd(aFieldFill, CriaVar(SX3->X3_CAMPO))
    Endif
Next nX
  
Aadd(aFieldFill, .F.)
Aadd(aColsExD, aFieldFill)
	
oMSNewGe2 := MsNewGetDados():New( 120, 002, 180, 530, /*GD_INSERT+GD_DELETE+GD_UPDATE*/, "AllwaysTrue", "AllwaysTrue", "", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeaderEx, aColsExD)
Return


Static Function ATPC005()
Local cQuery

cQuery := ""
cQuery := " SELECT SC7.C7_NUM,SC7.C7_ITEM,SC7.C7_PRODUTO,SB1.B1_DESC,SC7.C7_QUANT-SC7.C7_QUJE C7_QUANT,SC7.C7_PRECO,SB1.B1_GRUPO,SB1.B1_UM,SB1.B1_SEGUM,SB1.B1_TIPCONV "
cQuery += " FROM " + RetSqlName("SC7") + " SC7 "
cQuery += " JOIN " + RetSqlName("SB1") + " SB1 "
cQuery += "   ON SC7.D_E_L_E_T_ = SB1.D_E_L_E_T_ "
cQuery += "   AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'"
cQuery += "   AND SB1.B1_COD = SC7.C7_PRODUTO"
cQuery += " WHERE SC7.D_E_L_E_T_ <> '*' "
cQuery += " AND SC7.C7_FILIAL = '"+xFilial("SC7")+"'"
cQuery += " AND SC7.C7_FORNECE = '"+UP2->UP2_FORNEC+"'"
cQuery += " AND SC7.C7_LOJA = '"+UP2->UP2_LOJA+"'"
cQuery += " AND SC7.C7_PRODUTO = '"+aColsEx[oMSNewGe1:oBrowse:nAt,2]+"'" 
cQuery += " AND SC7.C7_QUANT-SC7.C7_QUJE > 0"

//somente pedidos de compra liberados
If lPCLib
	cQuery += " AND SC7.C7_CONAPRO = 'L'"
Endif

cQuery += " ORDER BY SC7.C7_NUM,SC7.C7_ITEM"

VerTabela("XML05PC")
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05PC",.T.,.T.)

aColsExD := {}
XML05PC->(DBGOTOP())
Do While !XML05PC->(Eof()) 
	
	//tenho que verificar se tem saldo com tolerancia 
	If aColsEx[oMSNewGe1:oBrowse:nAt,4] > XML05PC->C7_QUANT
		If lTolera  //se o parametro de tolerancia esta ativo e se tem registro
			If Tolera(UP2->UP2_FORNEC,UP2->UP2_LOJA,XML05PC->B1_GRUPO,aColsEx[oMSNewGe1:oBrowse:nAt,2],aColsEx[oMSNewGe1:oBrowse:nAt,4],XML05PC->C7_QUANT)
				ADColsEX(@aColsExD)
			Endif	
		Else  //questão da segunda unidade de medida
			If XML05PC->B1_SEGUM = aColsEx[oMSNewGe1:oBrowse:nAt,8]
				ADColsEX(@aColsExD)
			Endif
		Endif
	Else
		ADColsEX(@aColsExD)	
	Endif
	
	XML05PC->(dbSkip())
Enddo
VerTabela("XML05PC")

oMSNewGe2:SetArray(aColsExD)
oMSNewGe2:Refresh()
Return


Static Function ADColsEX(aClExD)
Local aFieldFill := {}
			
	aFieldFill := {}
	Aadd(aFieldFill, XML05PC->C7_NUM)
	Aadd(aFieldFill, XML05PC->C7_ITEM)
	Aadd(aFieldFill, XML05PC->C7_PRODUTO)
	Aadd(aFieldFill, XML05PC->B1_DESC)
	Aadd(aFieldFill, XML05PC->C7_QUANT)
	Aadd(aFieldFill, XML05PC->C7_PRECO)
	Aadd(aFieldFill, .F.)
	Aadd(aClExD, aFieldFill) 
Return


Static Function Tolera(cFornec,cLoja,cGrupo,cProd,nQtdeXML,nQtdePC)
Local lRet := .F.
Local cQueryF      
Local cQuery
      
	cQueryF := ""
	cQueryF := " SELECT AIC_PQTDE "
	cQueryF += " FROM " + RetSqlName("AIC") 
	cQueryF += " WHERE D_E_L_E_T_ <> '*' "
	cQueryF += " AND AIC_FILIAL = '"+xFilial("AIC")+"'"
	    
	//POR PRODUTO E FORNECEDOR
	cQuery := cQueryF + " AND AIC_PRODUT = '"+cProd+"' AND AIC_FORNEC = '"+cFornec+"' AND AIC_LOJA = '"+cLoja+"'"
	VerTabela("XML05TL")
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05TL",.T.,.T.)
    
	If !Empty(XML05TL->AIC_PQTDE)  
		//vejo se está dentro do percentual		
		If nQtdeXML <= (nQtdePC + (nQtdePC * XML05TL->AIC_PQTDE / 100))
			lRet := .T.
		Endif
	Endif 
		
	If !lRet
		//SOMENTE POR FORNECEDOR            
		cQuery := cQueryF + " AND AIC_PRODUT = ' ' AND AIC_FORNEC = '"+cFornec+"' AND AIC_LOJA = '"+cLoja+"'"
		VerTabela("XML05TL")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05TL",.T.,.T.)
           
        If !Empty(XML05TL->AIC_PQTDE)  
			//vejo se está dentro do percentual		
			If nQtdeXML <= (nQtdePC + (nQtdePC * XML05TL->AIC_PQTDE / 100))  
				lRet := .T.
			Endif
		Endif	
	Endif 
    
	If !lRet
		//SOMENTE POR PRODUTO   
		cQuery := cQueryF + " AND AIC_PRODUT = '"+cProd+"' AND AIC_FORNEC = ' ' AND AIC_LOJA = ' '"
		VerTabela("XML05TL")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05TL",.T.,.T.)
            
        If !Empty(XML05TL->AIC_PQTDE)  
			//vejo se está dentro do percentual		
			If nQtdeXML <= (nQtdePC + (nQtdePC * XML05TL->AIC_PQTDE / 100))
				lRet := .T.
			Endif
		Endif	
	Endif 
        
	If !lRet
		// SOMENTE POR GRUPO DE PRODUTO 
		cQuery := cQueryF + " AND AIC_GRUPO = '"+cGrupo+"' AND AIC_FORNEC = ' ' AND AIC_LOJA = ' ' AND AIC_PRODUT = ' '"
		VerTabela("XML05TL")
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"XML05TL",.T.,.T.)
            
        If !Empty(XML05TL->AIC_PQTDE)  
			//vejo se está dentro do percentual		
			If nQtdeXML <= (nQtdePC + (nQtdePC * XML05TL->AIC_PQTDE / 100))
				lRet := .T.
			Endif
		Endif	
	Endif 

	VerTabela("XML05TL")
Return(lRet)


User Function XML05OK()
	Local	aArea		:= GetArea()
	Local	aAreaUP3	:= UP3->(GetArea())
	Local	cProd		:= AllTrim(M->UP3_COD)
	Local   cDescr      := ""
	Local	lRet		:= .T.
	Local	lSeek		:= .F.
	Local	cDocumento	:= UP2->UP2_DOC
	Local	cSerie		:= UP2->UP2_SERIE
	Local	cFornecedor	:= UP2->UP2_FORNEC
	Local	cLoja		:= UP2->UP2_LOJA
	Local	cRecnoPai	:= UP2->(Recno())
	
	Local	nPosProd	:= Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_COD"})
	Local	nPosDesc	:= Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_DESCR"})
	Local	nPosPed		:= Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_PEDIDO"})
	Local	nPosItem	:= Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_ITEMPC"})
	Local	nPosCrit	:= Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_CRITIC"})
	Local	nPosRECNO	:= Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_ID_PAI"})
	Local	nPosSeq   	:= Ascan(aHeader,{|x| Alltrim(x[2]) == "UP3_SEQ"})
	
	If !ExistCpo("SB1",cProd)
		lRet	:= .F.
	Else
		cDescr := Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC")
		
		//Busco registro na UP3 para atualizar codigo do item
		DbSelectArea("UP3")
		dbSetOrder(2)
		UP3->(DbGoTop())
		DbSeek(xFilial("UP3")+cDocumento+cSerie+cFornecedor+cLoja)
		While !UP3->(Eof()) .And. aCols[oGetDados:oBrowse:nAt, nPosRECNO] <> UP3->(RECNO())
			UP3->(DbSkip())
		EndDo
		
		//Atualizo codigo do produto no item
		RecLock("UP3",.F.)
		UP3->UP3_COD	:= cProd
		UP3->UP3_DESCR	:= cDescr
		UP3->UP3_PEDIDO	:= ""
		UP3->UP3_ITEMPC	:= ""
		UP3->UP3_CRITIC	:= ""
		UP3->UP3_STCRIT	:= "N"
		UP3->(MsUnlock())

		//Atualizo os dados do grid
		aCols[oGetDados:oBrowse:nAt,nPosProd]	:= cProd
		aCols[oGetDados:oBrowse:nAt,nPosDesc]	:= cDescr
		aCols[oGetDados:oBrowse:nAt,nPosPed]	:= ""
		aCols[oGetDados:oBrowse:nAt,nPosItem]	:= ""
		aCols[oGetDados:oBrowse:nAt,nPosCrit]	:= ""
	EndIf
	 
	RestArea(aAreaUP3)
	RestArea(aArea)
Return(lRet)
