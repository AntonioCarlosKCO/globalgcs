#INCLUDE 'Protheus.ch' 

Static Versao	:= "V1.01"   

/*  
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    | PRT0201    ³Autor ³ Marcos               	   |Data ³ 01/10/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao | Faz o processamento do arquivo xml CT-e no diretorio NEW para	³±± 
±±³			 | gravar os registros do arquivo XML nas tabelas SDS e SDT.		³±± 
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros| cFile: caminho do Arquivo XML.                              		³±±
±±³          | aProc: grava msgs de sucesso no array aProc durante a importacao.³±±
±±³          | aErros: grava msg de falha no array durante a importacao.	  	³±±   
±±³          | oXMl: objeto com o conteudo XML do documento.					³±±   
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±       
±±³ Uso      ³                                  					        	³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±       
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±      
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ*/ 

User Function XMLMA004(cErro,cFile,aProc,aErros,oXml,cPath,cArq,cCFOP)
Local lRet       := .T.
Local lRemet     := .F.
Local lDelFile   := .T.
Local nX         := 0
Local nPesoBruto := 0
Local nPesoLiqui := 0
Local cError     := ""
Local cDocumento := ""
Local cCNPJ_CT	 := ""
Local cCNPJ_CF	 := ""
Local cFornCTe   := ""
Local cLojaCTe   := ""
Local cNomeCTe   := ""
Local cCodiRem   := ""
Local cLojaRem   := ""
Local cChaveNF   := ""
Local cTES_CT 	 := ""
Local cCPag_CT 	 := ""
Local cTipoFrete := ""
Local aDadosFor  := Array(2) //-- 1- Codigo; 2-Loja
Local aDadosCli  := Array(2) //-- 1- Codigo; 2-Loja
Local aCabec116	 := {}
Local aItens116	 := {}
Local aAux		 := {}
Local aEspecVol  := {}
Local aItens	 := {}
Local lClassifNF := SuperGetMV("XML_CLASNF", .F. ,.F.               , /*cFilial*/)  // Se classifica automaticamente
Local cTES       := SuperGetMV("XML_TESNF" , .F. ,''                , /*cFilial*/)  // Codigo da TES usado para mata103 na classificaçao automatica
Local cCC        := SuperGetMV("XML_CC"    , .F. ,"101101"          , /*cFilial*/)  // Centro de Custo usado para mata103 na classificaçao automatica
Local cCndPgto   := SuperGetMV("XML_CND"   , .F. ,"001"             , /*cFilial*/)  // Condicao de pagamento padrao
Local cCTaCtb    := SuperGetMV("XML_CCTB"  , .F. ,"111111100002"    , /*cFilial*/)  // Condicao de pagamento padrao
Local cQuery     := ""
Local cNotas     := ""
Local cOper      := ""
Local nTotal     := 0
Local nUnit      := 0
Local nCalc      := 0
Local lVcte      := .F.                              
Local nValIcms   := 0                       
Local nBasIcms   := 0
Local nPerIcms   := 0
Local cDatVenc   := ""
Local cDatVenR   := ""
Local cDiaMes    := ""
Local nRECNOPAI  := 0

Private cConheci := ''
Private cSer     := ''
Default aProc    := {}
Default aErros   := {}
Private cPerg    := "XMLM04"
Private nVlTot   := 0

//-- Verifica se o fornecedor do conhecimento esta cadastrado no sistema.
If ValType(XmlChildEx(oXML:_InfCte:_Emit,"_CNPJ")) <> "U"
	cCNPJ_CT := AllTrim(oXML:_InfCte:_Emit:_CNPJ:Text)
Else
	cCNPJ_CT := AllTrim(oXML:_InfCte:_Emit:_CPF:Text)
EndIf
	
SA2->(dbSetOrder(3))
If !SA2->(dbSeek(xFilial("SA2")+cCNPJ_CT))
	cErro := "Fornecedor: [" + Substr(Alltrim(oXML:_InfCte:_Emit:_Xnome:Text),1,60) + "] inexistente."
	lRet  := .F.
	Return lRet
Else
	If AllTrim(SA2->A2_MSBLQL) = "2"
		cFornCTe := SA2->A2_COD
		cLojaCTe := SA2->A2_LOJA
		cNomeCTe := SA2->A2_NOME
	Else
		cErro := "Fornecedor: [" + Substr(Alltrim(oXML:_InfCte:_Emit:_Xnome:Text),1,60) + "] bloqueado."
		lRet  := .F.
		Return lRet
	Endif	
EndIf

//-- Verifica se o arquivo pertence a filial corrente
If !Empty(SM0->M0_CGC)
	If !CTe_VldEmp(oXML,SM0->M0_CGC)
		cErro    := "Arquivo XML pertence a outra empresa/filial"
		lDelFile := .F.
		lRet     := .F.
		Return lRet
	EndIf
Endif	

// Verificar se pre nota ja foi incluida no protheus SF1
SF1->(dbSetOrder(8))
If lRet .And. SF1->(dbSeek(xFilial("SF1")+Right(AllTrim(oXML:_InfCte:_Id:Text),44)))
	cErro := "Arquivo XML já importado"
	lRet  := .F.
	Return lRet
EndIf

//pergunte
If !lAutomatic
	cConheci   := oXML:_InfCte:_Ide:_nCt:Text            //"Número do Conhecimento" 
	cSer       := AllTrim(oXML:_InfCte:_Ide:_Serie:Text) //"Serie"
	
	AjustaSX1(cPerg)
	
	If !Pergunte(cPerg,.T.,"Parametros - CTE")
		cErro := "Processo cancelado pelo usuário"
		lRet  := .F.
		Return lRet
	Endif
	
    //vejo se o codigo digitado eh valido
    dBSelectArea("SB1")
    SB1->(DbSetOrder(1))
	If !SB1->(DbSeek(xFilial("SB1")+MV_PAR01))  
		cErro := "Código Produto CTE não encontrado no Protheus"
		lRet  := .F.
		Return lRet
	Endif
	SB1->(dBCloseArea())
	
	lAutomatic := If(MV_PAR03=2,.T.,.F.) //Sim =1, Nao=2, se 1 eh manual
	cPrdFrete  := PadR(MV_PAR01,TamSX3("B1_COD")[1])	
EndIf


If lRet
	If ValType(XmlChildEx(oXML:_InfCte:_Rem,"_CNPJ")) <> "U"
		cCNPJ_CF := AllTrim(oXML:_InfCte:_Rem:_CNPJ:Text)
	Else
		cCNPJ_CF := AllTrim(oXML:_InfCte:_Rem:_CPF:Text)
	EndIf
	
	If lRemet := (SM0->M0_CGC == cCNPJ_CF) 
		//-- Armazena o CNPJ do destinatario das notas contidas no conhecimento
		If ValType(XmlChildEx(oXML:_InfCte:_Dest,"_CNPJ")) <> "U"
			cCNPJ_CF := AllTrim(oXML:_InfCte:_Dest:_CNPJ:Text) //-- Armazena o CNPJ do destinatario das notas contidas no conhecimento
		Else
			cCNPJ_CF := AllTrim(oXML:_InfCte:_Dest:_CPF:Text)
		EndIf
			
		cTipoFrete := "F"
	Else
		cCNPJ_CF := cCNPJ_CF //-- Armazena o CNPJ do remetente das notas contidas no conhecimento
		
		If lRemet
			cCNPJ_CF := cCNPJ_CT
			cTipoFrete := "F"
		Else
			cCNPJ_CF := cCNPJ_CT
			cTipoFrete := "C"
		Endif
		
		//-- Como no XML nao e possivel saber se o destinatario e cliente ou fornecedor    //	//-- Validarei os dois casos
		SA1->(dbSetOrder(3))
		If SA1->(dbSeek(xFilial("SA1")+cCNPJ_CF))
			aDadosCli[1] := SA1->A1_COD
			aDadosCli[2] := SA1->A1_LOJA
		Else
			aDadosCli[1] := CriaVar("A1_COD",.F.)
			aDadosCli[2] := CriaVar("A1_LOJA",.F.)
		EndIf
		
		SA2->(dbSetOrder(3))
		If SA2->(dbSeek(xFilial("SA2")+cCNPJ_CF))
			aDadosFor[1] := SA2->A2_COD
			aDadosFor[2] := SA2->A2_LOJA
		Else
			aDadosFor[1] := CriaVar("A2_COD",.F.)
			aDadosFor[2] := CriaVar("A2_LOJA",.F.)
		EndIf
		
		If Empty(aDadosCli[1]) .And. !Empty(aDadosFor[1])
			cCodiRem := aDadosFor[1]
			cLojaRem := aDadosFor[2]
		ElseIf !Empty(aDadosCli[1]) .And. Empty(aDadosFor[1])
			cCodiRem := aDadosCli[1]
			cCodiRem := aDadosCli[2]
		ElseIf !Empty(aDadosCli[1]) .And. !Empty(aDadosFor[1])
			cCodiRem := aDadosFor[1]
			cLojaRem := aDadosFor[2]
		Else
			cErro := "Fornecedor: [" + Substr(Alltrim(oXML:_InfCte:_Emit:_Xnome:Text),1,60) + "] inexistente."
			lRet  := .F.
		EndIf
	EndIf
EndIf

If lRet
	// tratamento para nota normal de CTE
	If ValType("oXML:_InfCte:_InfCteNorm") == "O"
		aAux := If(ValType(oXML:_InfCte:_InfCteNorm:_InfCarga:_InfQ) == "O",{oXML:_InfCte:_InfCteNorm:_InfCarga:_InfQ},oXML:_InfCte:_InfCteNorm:_InfCarga:_InfQ)
		For nX := 1 To Len(aAux)
			If Upper(AllTrim(aAux[nX]:_TPMED:Text)) == "PESO REAL"
				nPesoBruto := Val(aAux[nX]:_QCARGA:Text)
			EndIf
			
			If Upper(AllTrim(aAux[nX]:_TPMED:Text)) == "PESO BASE DE CALCULO"
				nPesoLiqui := Val(aAux[nX]:_QCARGA:Text)
			EndIf
			
			If !("PESO" $ Upper(aAux[nX]:_TPMED:Text)) .And. Len(aEspecVol) < 5
				aAdd(aEspecVol,{AllTrim(aAux[nX]:_TPMED:Text),Val(aAux[nX]:_QCARGA:Text)})
			EndIf
		Next nX
	Else
		aAdd(aEspecVol,{'',0})
	EndIf

	//ICMS: base de calculo, percentual e valor
	nValIcms := 0                       
    nBasIcms := 0
	nPerIcms := 0

	If XmlChildEx(oXML:_InfCte,"_IMP") != Nil
    	If XmlChildEx(oXML:_InfCte:_Imp,"_ICMS") != Nil  			
    		If XmlChildEx(oXML:_InfCte:_Imp:_ICMS,'_ICMS00') != Nil    					
    			If XmlChildEx(oXML:_InfCte:_Imp:_ICMS:_ICMS00,'_VBC') != Nil      				 
	   		       	nBasIcms := Val(oXML:_InfCte:_Imp:_ICMS:_ICMS00:_vBC:Text)
    		    Endif
    		        
    			If XmlChildEx(oXML:_InfCte:_Imp:_ICMS:_ICMS00,'_PICMS') != Nil    
    		   		nPerIcms := Val(oXML:_InfCte:_Imp:_ICMS:_ICMS00:_pICMS:Text)
    	     	Endif                                                                            
    		        
	   			If XmlChildEx(oXML:_InfCte:_Imp:_ICMS:_ICMS00,'_VICMS') != Nil    
    		       	nValIcms := Val(oXML:_InfCte:_Imp:_ICMS:_ICMS00:_vICMS:Text)
    		    Endif                                                                            
    		Endif
        Endif
	Endif	
	
	//Verifica se o valor da nota foi informado, o valor pode estar em uma das TAGs abaixo
	If ValType("oXML:_InfCte:_VPrest:_VRec:Text") <> "U"
		If !Empty(Val(oXML:_InfCte:_VPrest:_VRec:Text))
			nVlTot := Val(oXML:_InfCte:_VPrest:_VRec:Text)
		Endif	
	Endif	
	
	If nVlTot = 0
		If ValType("oXML:_InfCte:_VPrest:_vTPrest:Text") <> "U"
			If !Empty(Val(oXML:_InfCte:_VPrest:_vTPrest:Text))
				nVlTot := Val(oXML:_InfCte:_VPrest:_vTPrest:Text)
			Endif	
		Endif	
	Endif
		
	If nVlTot = 0		
		cErro := "Valor do CTE inválido, verifique o arquivo XML."+CRLF+"Valor: 0"
		lRet  := .F.
		Return lRet
	EndIf
	
	DisarmTran()
	Begin Transaction
	
	cDocumento	:= PadL(Trim(oXML:_InfCte:_Ide:_nCt:Text),TamSx3("F1_DOC")[1],'0')
	
	//-- Grava as tabelas de CTE
	Dbselectarea("SDS")
	SDS->(dbSetOrder(2))
	If !SDS->(dbSeek(xFilial("SDS")+Right(AllTrim(oXML:_InfCte:_Id:Text),44)))
		RecLock("SDS",.T.)
    Else
		RecLock("SDS",.F.)    
    Endif

	SDS->DS_FILIAL		:= xFilial("SDS")													// Filial
	SDS->DS_CNPJ		:= cCNPJ_CT															// CGC
	SDS->DS_DOC			:= cDocumento														// Numero do Documento
	SDS->DS_SERIE		:= AllTrim(oXML:_InfCte:_Ide:_Serie:Text) 							// Serie
	SDS->DS_FORNEC		:= cFornCTe															// Fornecedor do Conhecimento de transporte
	SDS->DS_LOJA		:= cLojaCTe															// Loja do Fornecedor do Conhecimento de transporte
	SDS->DS_EMISSA		:= StoD(StrTran(AllTrim(oXML:_InfCte:_Ide:_Dhemi:Text),"-",""))		// Data de Emissão
	SDS->DS_EST			:= oXML:_InfCte:_Ide:_UFIni:TEXT									// Estado de emissao da NF
	SDS->DS_TIPO		:= "T"													 			// Tipo da Nota
	SDS->DS_FORMUL		:= "N" 																// Formulario proprio
	SDS->DS_ESPECI		:= "CTE"															// Especie
	SDS->DS_ARQUIVO		:= AllTrim(cFile)													// Arquivo importado
	SDS->DS_CHAVENF		:= Right(AllTrim(oXML:_InfCte:_Id:Text),44)							// Chave de Acesso da NF
	SDS->DS_VERSAO		:= AllTrim(oXML:_InfCte:_Versao:Text) 								// Versão
	SDS->DS_USERIMP		:= cUserName                             							// Usuario na importacao
	SDS->DS_DATAIMP		:= dDataBase														// Data importacao do XML
	SDS->DS_HORAIMP		:= SubStr(Time(),1,5)												// Hora importacao XML
	For nX := 1 To Len(aEspecVol)
		If SDS->(FieldPos("DS_ESPECI" +Str(nX,1))) > 0
			SDS->&("DS_ESPECI" +Str(nX,1)) := aEspecVol[nX,1]							 	// Especie
			SDS->&("DS_VOLUME" +Str(nX,1)) := aEspecVol[nX,2]							 	// Volume
		EndIf
	Next nX
	SDS->(MsUnlock())
	
	Dbselectarea("SDT")
	SDT->(dbSetOrder(1))
	If !SDT->(dbSeek(xFilial("SDT")+SDS->DS_CNPJ+cFornCTe+cLojaCTe+cDocumento+AllTrim(oXML:_InfCte:_Ide:_Serie:Text)))
		RecLock("SDT",.T.)
    Else
   		RecLock("SDT",.F.)    
    Endif
		
	SDT->DT_FILIAL		:= xFilial("SDT")                                        // Filial
	SDT->DT_ITEM		:= StrZero(1,TamSX3("DT_ITEM")[1])                       // Item
	SDT->DT_COD			:= cPrdFrete                                             // Codigo do produto
	SDT->DT_FORNEC		:= cFornCTe                                              // Forncedor
	SDT->DT_LOJA		:= cLojaCTe                                              // Loja
	SDT->DT_DOC			:= cDocumento                                            // Docto
	SDT->DT_SERIE		:= AllTrim(oXML:_InfCte:_Ide:_Serie:Text)                // Serie
	SDT->DT_CNPJ		:= SDS->DS_CNPJ                                          // Cnpj do Fornecedor
	SDT->DT_VUNIT		:= nVlTot                                                // Valor Unitário
	SDT->DT_TOTAL		:= nVlTot                                                // Valor Total
	SDT->(MsUnlock())

	//-- Grava as tabelas de Importacao
	Dbselectarea("UP2")
	UP2->(dbSetOrder(1))
	If !UP2->(dbSeek(xFilial("UP2")+cDocumento+AllTrim(oXML:_InfCte:_Ide:_Serie:Text)+cFornCTe+cLojaCTe))
		RecLock("UP2",.T.)
    Else
		RecLock("UP2",.F.)    
    Endif
    
    UP2->UP2_FILIAL := xFilial("UP2")
    UP2->UP2_TIPO   := "C"
    UP2->UP2_FORMUL := "N"
    UP2->UP2_DOC    := cDocumento
    UP2->UP2_SERIE  := PadR(oXML:_InfCte:_Ide:_Serie:Text,TamSx3("F1_SERIE")[1])
    UP2->UP2_FORNEC := cFornCTe
    UP2->UP2_LOJA   := cLojaCTe
    UP2->UP2_NOME   := POSICIONE("SA2",1,XFILIAL("SA2")+cFornCTe+cLojaCTe,"SA2->A2_NOME") 
    UP2->UP2_CHVNFE := Right(AllTrim(oXML:_InfCte:_Id:Text),44)
    UP2->UP2_ESPEC1 := "CTE"
    UP2->UP2_VOLUME := 0
    UP2->UP2_PLIQUI := 0
    UP2->UP2_PBRUTO := 0
    UP2->UP2_EMISSA := StoD(StrTran(AllTrim(oXML:_InfCte:_Ide:_Dhemi:Text),"-",""))
    UP2->UP2_TRANSP := ""
    UP2->UP2_ESPECI := "CTE"
    UP2->UP2_CRITIC := "N"
    UP2->UP2_BASE   := nBasIcms
    UP2->UP2_VICMS  := nValIcms
    UP2->UP2_VTOTAL := nVlTot
    UP2->UP2_VNF    := nVlTot
    UP2_STATUS      := "P"  //envia direto para o Protheus
    UP2->UP2_PROCES := "S"
    UP2->UP2_CONSUM := "N"
    UP2->UP2_ARQXML := cArq
    UP2->UP2_USER := RetCodUsr()
    UP2->UP2_DATA := Date()
    UP2->UP2_HORA := Time()
    UP2->(MsUnlock())
    nRECNOPAI := UP2->(Recno())
    
    DbSelectArea("UP3")
    UP3->(DbSetOrder(2))
	If !UP3->(dbSeek(xFilial("UP3")+cDocumento+AllTrim(oXML:_InfCte:_Ide:_Serie:Text)+cFornCTe+cLojaCTe))
		RecLock("UP3",.T.)
    Else
		RecLock("UP3",.F.)    
    Endif
    
    UP3->UP3_FILIAL := xFilial("UP3")  
    UP3->UP3_DOC    := cDocumento
    UP3->UP3_SERIE  := PadR(oXML:_InfCte:_Ide:_Serie:Text,TamSx3("F1_SERIE")[1])
    UP3->UP3_EMISSA := StoD(StrTran(AllTrim(oXML:_InfCte:_Ide:_Dhemi:Text),"-",""))
    UP3->UP3_FORNEC := cFornCTe
    UP3->UP3_LOJA   := cLojaCTe
    UP3->UP3_COD    := cPrdFrete
    UP3->UP3_DESCR  := POSICIONE("SB1",1,XFILIAL("SB1")+cPrdFrete,"B1_DESC") 
    UP3->UP3_SEQ    := StrZero(1,TamSX3("D1_ITEM")[1])
    UP3->UP3_QUANT  := 1
    UP3->UP3_VUNIT  := nVlTot
    UP3->UP3_TOTAL  := nVlTot
    UP3->UP3_CRITIC := ""
    UP3->UP3_STCRIT := "N"
    UP3->UP3_CFOP   := cCFOP
    UP3->UP3_NCM    := ""
    UP3->UP3_VICMS  := nValIcms
    UP3->UP3_PICMS  := nPerIcms
    UP3->UP3_TOTIMP := nVlTot
    UP3->UP3_USER   := RetCodUsr()
    UP3->UP3_DATA   := Date()
    UP3->UP3_HORA   := Time()
    UP3->UP3_CLASFI := ""
    UP3->UP3_ID_PAI := nRECNOPAI
    UP3->(MsUnlock())
	
	//-- tabelas do Protheus
	aCabec := {}
		
	aadd(aCabec,{"F1_TIPO"   ,"N"})
	aadd(aCabec,{"F1_FORMUL" ,"N"})
	aadd(aCabec,{"F1_DOC"    ,cDocumento})
	aadd(aCabec,{"F1_SERIE" ,PadR(oXML:_InfCte:_Ide:_Serie:Text,TamSx3("F1_SERIE")[1])})
	aadd(aCabec,{"F1_EMISSAO",SToD(Substr(StrTran(oXML:_InfCte:_Ide:_dhEmi:Text,"-",""),1,8))})
	aadd(aCabec,{"F1_FORNECE",cFornCTe})
	aadd(aCabec,{"F1_LOJA"   ,cLojaCTe})
	aadd(aCabec,{"F1_ESPECIE","CTE"})
	aadd(aCabec,{"F1_COND"   ,cCndPgto})
	aadd(aCabec,{"F1_CHVNFE",Right(AllTrim(oXML:_InfCte:_Id:Text),44),NIL})
	aadd(aCabec,{"F1_VALMERC",nVlTot,NIL})
	aadd(aCabec,{"F1_VALBRUT",nVlTot,NIL})
	aadd(aCabec,{"F1_PLIQUI",nPesoLIQUI,NIL})
	aadd(aCabec,{"F1_PBRUTO",nPesoBruto,NIL})
		
	If LEN(aEspecVol) > 0
		aadd(aCabec,{"F1_ESPECI1",aEspecVol[1,1],NIL})
		aadd(aCabec,{"F1_VOLUME1",aEspecVol[1,2],NIL})
	Endif
		
	aLinha := {}
	aItens := {}
	aadd(aLinha,{"D1_ITEM"    ,StrZero(1,TamSX3("D1_ITEM")[1]) ,Nil})
	aadd(aLinha,{"D1_FILIAL"  ,xFilial("SD1")                  ,Nil})
	aadd(aLinha,{"D1_COD"     ,cPrdFrete                       ,Nil})
	aadd(aLinha,{"D1_QUANT"   ,1                               ,Nil})
	aadd(aLinha,{"D1_VUNIT"   ,nVlTot                          ,Nil})
	aadd(aLinha,{"D1_TOTAL"   ,nVlTot                          ,Nil}) //Valor total proporcional
	aadd(aLinha,{"D1_BASEICM" ,nBasIcms                        ,Nil})
	aadd(aLinha,{"D1_VALICM"  ,nValIcms                        ,Nil})
	aadd(aLinha,{"D1_PICM"    ,nPerIcms                        ,Nil})
			
	//classificar o CTE automaticamente considerando a seguinte regra:
	If lClassifNF
		aadd(aLinha,{"D1_TES"  		,cTES                    ,Nil})
		aadd(aLinha,{"D1_CC"        ,cCC                     ,Nil})
		aadd(aLinha,{"D1_CONTA"     ,cCTaCtb                 ,Nil})
	Endif
		
	// Incluir sempre no ultimo elemento do array de cada item
	aadd(aLinha,{"AUTDELETA","N"                 ,Nil})
	aadd(aItens,aLinha) // Chave para tratamentos especificos
		
	//³ Executa a ExecAuto do MATA116 para gravar os itens com o valor de frete rateado ³
	lMsErroAuto    := .F.
	lAutoErrNoFile := .T.
		
	If lClassifNF
		MSExecAuto( { |x,y,z| Mata103(x,y,z)}, aCabec, aItens, 3)   //Execauto que inclui documento de entrada e classifica
	Else
		MSExecAuto( { |x,y,z| Mata140(x,y,z)}, aCabec, aItens, 3)
	EndIf
		
	If lMsErroAuto
		DisarmTran()
			
		aAux := GetAutoGRLog()
    	For nX := 1 To Len(aAux)                    
    	
			cError += aAux[nX]
		Next nX
	
		cErro := cError
		lRet  := .F.
	ElseIf lClassifNF  //classificacao automatica
			
		//tenho que atualizar a data dos contas a pagar (SE2) de acordo com a regra da STR
		cDatVenc := Substr(StrTran(oXML:_InfCte:_Ide:_dhEmi:Text,"-",""),1,8)
		cDiaMes  := Val(Substr(cDatVenc,7,2))
			
		If (cDiaMes <= 15)                          //ultimo dia do mes
			cDatVenc := Lastday(SToD(cDatVenc),0)
			cDatVenR := Lastday(cDatVenc,3)
			cDatVenc := DTOS(cDatVenc) 
		Else                                        //dia 15 do proximo mes
			cDatVenc := STOD(cDatVenc)
			cDatVenc := MonthSum(cDatVenc,1)        //somo 1 mes
			cDatVenc := DTOS(cDatVenc) 
			cDatVenc := Substr(cDatVenc,1,6)+"15"
			cDatVenR := Lastday(STOD(cDatVenc),3)
		Endif
			
		cQuery := " UPDATE "+RetSQLName("SE2") 
        cQuery += " SET E2_VENCTO = '"+cDatVenc+"', E2_VENCORI = '"+cDatVenc+"', E2_VENCREA = '"+DTOS(cDatVenR)+"', E2_NATUREZ = '4110602' "       
       	cQuery += " WHERE D_E_L_E_T_ <> '*' "
       	cQuery += " AND E2_FILIAL = '"+xFilial("SE2")+"'"
       	cQuery += " AND E2_EMISSAO = '"+Substr(StrTran(oXML:_InfCte:_Ide:_dhEmi:Text,"-",""),1,8)+"'"
       	cQuery += " AND E2_NUM = '"+cDocumento+"'"
       	cQuery += " AND E2_FORNECE = '"+cFornCTe+"'"
       	cQuery += " AND E2_LOJA = '"+cLojaCTe+"'"
		TcSqlExec(cQuery)
    Endif
	
	End Transaction
EndIf
                         
Private cDirLidos := cPath+"ARQ_IMPORTADO\"
If !ExistDir(cDirLidos)
	Cria_Dir(cDirLidos)
EndIf

Private cDirErros := cPath+"ARQ_ERRO\"
If !ExistDir(cDirErros)
	Cria_Dir(cDirErros)
EndIf

If lRet
	__CopyFile(cPath+cFile,cDirLidos+cfile)
	FErase(cPath+cFile)
	
	aAdd(aProc,{PadL(Trim(oXML:_InfCte:_Ide:_nCt:Text),TamSx3("F1_DOC")[1],'0'),;
	PadR(oXML:_InfCte:_Ide:_Serie:Text,TamSx3("F1_SERIE")[1]),;
	cNomeCTe})
ElseIf lDelFile
	__CopyFile(cPath+cFile,cDirErros+cfile)
	FErase(cPath+cFile)
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³CTe_VldEmpºAutor  ³ Marcos             º      ³             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Verifica se o XML deve ser processado pela empresa.        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ oXml: XML do arquivo CTe.								  º±±
±±º			 ³ cCNPJ_CPF: CNPJ/CPF da empresa que ira processar.		  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno	 ³ lRet: indica se o arquivo deve ser processado.			  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º			 ³                                                            º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function CTe_VldEmp(oXML,cCNPJ_CPF)
Local lRet 	   	:= .T.
Local cTagRem  	:= If(ValType(XmlChildEx(oXML:_InfCte:_Rem,"_CNPJ")) == "O","_CNPJ","_CPF")
Local cTagDest 	:= If(ValType(XmlChildEx(oXML:_InfCte:_Dest,"_CNPJ")) == "O","_CNPJ","_CPF")  
Local cTagTOMA4 :=  ""   

If ValType(XmlChildEx(oXML:_InfCte:_IDE,"_TOMA4")) <> "U" 
	cTagTOMA4   := If(ValType(XmlChildEx(oXML:_InfCte:_IDE:_TOMA4,"_CNPJ")) == "O","_CNPJ","_CPF")
Endif	     

//-- Verifica se o arquivo pertence a filial corrente
IF !empty(cTagTOMA4)
	lRet := AllTrim(XmlChildEx(oXML:_InfCte:_Rem,cTagRem):Text) == AllTrim(cCNPJ_CPF) .Or.;
			AllTrim(XmlChildEx(oXML:_InfCte:_Dest,cTagDest):Text) == AllTrim(cCNPJ_CPF) .Or.;	
		    AllTrim(XmlChildEx(oXML:_InfCte:_IDE:_TOMA4,cTagTOMA4):Text) == AllTrim(cCNPJ_CPF) 
Else
	lRet := AllTrim(XmlChildEx(oXML:_InfCte:_Rem,cTagRem):Text) == AllTrim(cCNPJ_CPF) .Or.;
			AllTrim(XmlChildEx(oXML:_InfCte:_Dest,cTagDest):Text) == AllTrim(cCNPJ_CPF) 
Endif
Return lRet

Static Function Cria_Dir(cDiretorio) 
	Local nRet := MakeDir(cDiretorio)

	If nRet != 0 
		MsgAlert("Não foi possível criar o diretório. Erro: " + cValToChar( FError() ),"Atencao!")
	EndIf
Return

Static Function AjustaSX1(cPerg)
Dbselectarea("SX1")
DbsetOrder(1)
If SX1->(dbSeek(PADR(cPerg,10)+Padl(cValToChar(3),2,"0"))) 
	If SX1->X1_ORDEM == "02"
		Reclock("SX1",.F.)
		SX1->X1_PERGUNTE := "N.Conh: " + PADL(AllTrim(cConheci),9,'0') +"-"+ cSer
		SX1->X1_CNT01    := cConheci
		SX1->(MsUnlock())
	EndIf
Endif
DbCloseArea("SX1")
 
aArea := GetArea()

PutSx1MA(cPerg,"01","Cód. Produto CTE:"                                  ,"","","mv_ch1" ,"C",TamSX3("B1_COD")[1],0,0,"G","","SB1" ,"","","MV_PAR01","","","","","" ,"","","","","","","","","","",{"Produto utilizado no CTE"}, {"Produto utilizado no CTE"}, {"Produto utilizado no CTE"})
PutSx1MA(cPerg,"02","N.CTE: " + PADL(AllTrim(cConheci),9,'0') +"-"+ cSer ,"","","mv_ch2" ,"C",00	             ,0,0,"G","",""    ,"","","MV_PAR02","","","",cConheci,"" ,"","","","","","","","","","",{"Número do Conhecimento" }, {"Número do Conhecimento"  }, {"Número do Conhecimento"  })
PutSx1MA(cPerg,"03","Processar Manual?"                                  ,"","","mv_ch3" ,"N",01                 ,0,1,"C","",""    ,"","","MV_PAR03","Sim", "Sim", "Sim", "", "Não", "Não", "Não", "","", "", "", "", "", "", "", "",{"Processar Manual."}, {"Processar Manual."}, {"Processar Manual."})

RestArea(aArea)
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
