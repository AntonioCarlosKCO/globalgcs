#Include "Protheus.ch"
#Include "Rwmake.ch"
#Include "Colors.ch"
#Include "Font.ch"
#Include "Hbutton.ch"
#Include "Topconn.ch"

Static versao := "V1.01"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัอออออออออออออออออออออออหออออออัออออออออออปฑฑ
ฑฑบPrograma  ณ XMLMA003  บ Autor ณ Marcos                                 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯอออออออออออออออออออออออสออออออฯออออออออออนฑฑ
ฑฑบDescricao ณ Leitura e Importacao Arquivo XML para gera็ใo de Pre-Nota  บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ 					                                          บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function XMLMA003()
  Local cFile        := Space(10)
  Private cTitulo    := "Importa็ใo de XML - " + Versao
  Private _cMarca    := GetMark()
  Private aFields    := {}
  Private aArq       := {}
  Private aFields2   := {}
  Private cArq2
  Private cErro      := ""
  Private cPath      := "" 
  Private lPerg      := .F.
  Private nTipo      := 0
  Private cCoddiret  := ""
  Private lValidaNFE := SuperGetMV("XML_VLDNFE" , .F. , .F.  ,  /*cFilial*/)   //Valida XML no Sefaz 
  Private lNCM   	 := SuperGetMV("XML_ATUNCM" , .F. , .T.  ,  /*cFilial*/)   //.T.=Atualiza NCM / .F.=Nao Atualiza NCM                                                                         
  Private lCpoxPed   := SuperGetMV("XML_CPXPED" , .F. , .F.  ,  /*cFilial*/)   //se eh obrigatorio ter o pedido de compra
  Private cTipoEspec := SuperGetMV("XML_ESPEC"  , .F. ,"SPED",  /*cFilial*/)   //especie da nota fiscal
  Private lNFAut     := SuperGetMV("XML_PNTAUT" , .F. , .F.  ,  /*cFilial*/)   //se gera prenota automatico sem passar pelo processo
  Private cProdSubst := SuperGetMV("XML_PRDGEN" , .F. , ""   ,  /*cFilial*/)   //C๓digo Produto uso e consumo
  Private lPCLib     := SuperGetMV("XML_PCLIB"  , .F. , .F.  ,  /*cFilial*/)   //Somente filtra pedidos de compra liberados

  XML00301()
Return

Static Function XML00301()
  Local nX           := 0
  Local aAlterFields := {}
  Local aSize        := {}
  Local aInfo        := {}
  Local aPosObj      := {}
  Local aObjects     := {}
  Local bActBtn      := nil
  Local oOK          := LoadBitmap(GetResources(),"LBOK")
  Local oNO          := LoadBitmap(GetResources(),"LBNO")
  Local oBtnBusca    := Nil
  Local oBtnSeleci   := Nil
  Local oBtnLerCod   := Nil
  Local oBtnProces   := Nil
  Local oDlg         := Nil
  Local oPanel1      := {}
  Local oPanel2      := {}
  Local oLblDiret    := Nil
  Local nOpcA        := 0
  Local cQuery
  Local aTam

  Private aButtons  := {}
  Private aBrowse   := {}
  Private aRotina   := {}
  Private aDiverg   := {} //"Arquivo","Pedido","Item","Divergencia"
  Private lChk      := .F.
  Private lChkCons  := .F.
  Private lChkTrans := .F.
  Private oGetDiret := {}
  Private cGetDiret := Space(1)
  Private oBrowse
  Private oCheck
  Private aHeader   := {}
  Private aCols     := {}
  Static oMSNewGe1

  aAdd(aBrowse,{.f.,"","","",.f.})

  //Definicao do tamanho do dialogo e dos objetos
  aSize := MsAdvSize(.F./*lEnchoice*/,.F.)
  aInfo := { aSize[1], aSize[2], aSize[3], aSize[4], 5, 5, 5, 5}
  AAdd( aObjects, { 100, 30, .T., .T.,.T. } )
  AAdd( aObjects, { 100, 70, .T., .T.,.T. } )
  aPosObj := MsObjSize( aInfo, aObjects, .T. )

  oDlg := MsDialog():New(aSize[7],0,aSize[6],aSize[5],cTitulo,,,,,/*nClrText*/,/*nClrBack*/,,, .T.,,,,,)

  //Painel Superior
  oPanel1 := TPanel():New(aPosObj[1,1],aPosObj[1,2],/*cText*/,oDlg,/*oFont*/,.T./*lCentered*/,/*uParam7*/,/*nClrText*/,/*nClrBack*/,aPosObj[1,3]/*nWidth*/ ,aPosObj[1,4]/*nHeight*/,.F./*lLowered*/,.F./*lRaised*/ )

  //MsNewGetDados
  cQuery := " SELECT UP1_CODIGO CODIGO,UP1_DESCRI DESCRICAO,UP1_PATH DIRETORIO" + CRLF
  cQuery += " FROM " + RetSqlName("UP1") + CRLF
  cQuery += " WHERE D_E_L_E_T_ <> '*'" + CRLF
  cQuery += " AND UP1_FILIAL = '"+xFilial("UP1")+"'" + CRLF
  cQuery += " ORDER BY UP1_CODIGO"
  
  IIf(Select("XML003") > 0, XML003->(dbCloseArea()), Nil)
  dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery ),"XML003",.F.,.F.)
		
  While !XML003->(EoF())
      AAdd(aCols, {XML003->CODIGO, Alltrim(XML003->DESCRICAO), Alltrim(XML003->DIRETORIO),.F.})
	
      If LEN(Alltrim(XML003->DIRETORIO)) > nX 
		  nX := LEN(Alltrim(XML003->DIRETORIO))
	  Endif
	
	  XML003->(dbSkip())
  EndDo 
  IIf(Select("XML003") > 0, XML003->(dbCloseArea()), Nil)
  
  aTam := TamSX3("UP1_CODIGO"); AAdd(aHeader, {"Codigo"   , "CODIGO"    , PesqPict("UP1","UP1_CODIGO" )  , aTam[1], aTam[2], "", "", aTam[3], "", ""})
  aTam := TamSX3("UP1_DESCRI"); AAdd(aHeader, {"Descricao", "DESCRICAO" , PesqPict("UP1","UP1_DESCRI" )  , aTam[1], aTam[2], "", "", aTam[3], "", ""})
  aTam := TamSX3("UP1_PATH" ) ; AAdd(aHeader, {"Diretorio", "DIRETORIO" , PesqPict("UP1","UP1_PATH"   )  , nX, 0, "", "", "C", "", ""})

  oMSNewGe1 := MsNewGetDados():New( 010, 005, 80, 500, , "AllwaysTrue", "AllwaysTrue", "", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oPanel1, aHeader, aCols)
  
  //Botoes
  oBtnSeleci := TButton():New(C(010),C(420),"Busca Arquivo(s)",oPanel1,{|| BuscaXML(aCols[oMSNewGe1:nAt,3])},C(050),C(012),,/*oFont*/,,.T.,,,,/*{||Iif(oGetDiret==Nil,.F.,.T.)}*/,,)
  oBtnProces := TButton():New(C(022),C(420),"Processamento",oPanel1,{|| XMLMA3P(aCols[oMSNewGe1:nAt,3])},C(050),C(012),,/*oFont*/,,.T.,,,,/*{||Iif(oBrowse == Nil, .F.,.T.)}*/,,)
  oBtnSair   := TButton():New(C(035),C(420),"Sair",oPanel1,{|| oDlg:End()},C(050),C(012),,/*oFont*/,,.T.,,,,/*{||Iif(oBrowse == Nil, .F.,.T.)}*/,,)
  
  //Painel Inferior
  oPanel2     := TPanel():New(aPosObj[2,1],aPosObj[2,2],/*cText*/,oDlg,/*oFont*/,.T./*lCentered*/,/*uParam7*/,/*nClrText*/,/*nClrBack*/,aPosObj[2,3]/*nWidth*/ ,aPosObj[2,4]/*nHeight*/,.F./*lLowered*/,.F./*lRaised*/ )
  //Grid
  oLblArquiv  := TSay():New(C(001),C(005),{||"Arquivos:"},oPanel2,/*cPicture*/,/*oFont*/,,,,.T.,CLR_BLUE/*nClrText*/,/*nClrBack*/,/*nWidth*/,/*nHeight*/,,,,,,/*lHTML*/)
  oBrowse     := TCBrowse():New(C(010),C(005),aPosObj[2,3]-10,aPosObj[2,4]-20,,{"","Diretorio","Nome do Arquivo","Status"},{50,200,200,1},oPanel2,,,,,,,,,,,"Arquivos XML",,/*cAlias*/,.T./*lPixel*/,/*bWhen*/,/*uparam*/,/*bValid*/,.T./*lHScroll*/,/*lVScroll*/.T.)

  //Definicao dos valores de dentro do grid
  oBrowse:SetArray(aBrowse)
  //Preenchimento de cada linha
  oBrowse:bLine := {||{If( aBrowse[oBrowse:nAT,01], oOk, oNO ),aBrowse[oBrowse:nAt,02],aBrowse[oBrowse:nAt,03],aBrowse[oBrowse:nAt,04]}}

  // Troca a imagem no duplo click do mouse sobre linha
  oBrowse:bLDblClick := {|| aBrowse[oBrowse:nAt][01] := !aBrowse[oBrowse:nAt][01],oBrowse:DrawSelect()}

  oCheck     := TCheckBox():New(C(001),C(035),'Selecionar todos',{ || lChk },oPanel2,C(100),C(200),,,,,,,,.T.,,,)
  //Clique do mouse sobre checkbox
  oCheck:bLClicked := {|| lChk := !lChk,aEval(aBrowse,{|x| x[1]:=lChk})}

  //Check para armazenar codigo de produto generico
  oCheckCons := TCheckBox():New(C(001),C(100),'Produto Gen้rico',{ || lChkCons },oPanel2,C(100),C(200),,,,,,,,.T.,,,)
  //Clique do mouse sobre checkbox
  oCheckCons:bLClicked := {|| lChkCons := !lChkCons, lChkTrans := .F.}

  //Check para armazenar codigo de tranferencia
  oCheckTrans := TCheckBox():New(C(001),C(170),'NF de Transferencia entre Filiais',{ || lChkTrans },oPanel2,C(100),C(200),,,,,,,,.T.,,,)
  //Clique do mouse sobre checkbox
  oCheckTrans:bLClicked := {|| lChkTrans := !lChkTrans, lChkCons := .F.}

  oDlg:Activate(,,,,,,/*{|| EnchoiceBar(oDlg,{|| nOpcA := 1,oDlg:End()},	{|| oDlg:End()},,aButtons)}*/)
Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณXMLMA3P  บAutor  ณMicrosiga           บ Data ณ  10/07/13   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณFuncao que realiza o processamento dos arquivos XML que sao บฑฑ
ฑฑบ          ณselecionados no grid                                        บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function XMLMA3P(cDir)
	Local aLinha    := {}
	Local nI        := 0
	Local I         := 0
	Local aSize     := {}
	Local aInfo     := {}
	Local aPosObj   := {}
	Local aObjects  := {}
	Local lRet      := .F.
	Local nPos      := 0
	Local lAtua     := .F.

	Private lErro      := .F. // Registra se ocorre erro em alguma etapa do processamento
	Private lCritica   := .F. // Registra se arquivo foi criticado para atualizar flag
	Private lAutomatic := .F.                        //Valida se o processamento de CTe pedira dados de produto
	Private cPrdFrete  := Space(TamSX3("B1_COD")[1]) //"Produto utilizado no CTE" 
	
	//Definicao do tamanho do dialogo e dos objetos
	aSize := MsAdvSize(.F./*lEnchoice*/,.F.)
	aInfo := { aSize[1], aSize[2], aSize[3], aSize[4], 5, 5, 5, 5}
	AAdd( aObjects, { 100, 100, .T., .T.,.T. } )
	aPosObj := MsObjSize( aInfo, aObjects, .T. ) 
	
	cGetDiret := cDir
	cPath     := Iif(Right(Alltrim(cGetDiret),1,1)=="\",Alltrim(cGetDiret),Alltrim(cGetDiret)+"\")
	
    Private cDirLidos := cPath+"ARQ_IMPORTADO\"
	Private cDirErros := cPath+"ARQ_ERRO\"
	
	If !ExistDir(cDirLidos)
		Cria_Dir(cDirLidos)
	EndIf
		
	If !ExistDir(cDirErros)
		Cria_Dir(cDirErros)
	EndIf

	aArq := {}
	
	If Len(aBrowse)> 0 
		If !Empty(aBrowse[1,2])
			For nI := 1 to Len(aBrowse)
				If aBrowse[nI,1]
					If File(aBrowse[nI,2]+aBrowse[nI,3])
						aLinha := Directory(aBrowse[nI,2]+aBrowse[nI,3])
						If Len(aLinha) > 0
							aAdd(aArq,aLinha[1])
							lRet := .T.
						Else 
							lRet := .F.
						EndIf
					Endif
				EndIf
			Next
			
			If Len(aArq) == 0
				MsgAlert("Realize a busca e selecao de arquivos XML para o processamento.",cTitulo)
			EndIf
		Else
			MsgAlert("Realize a busca e selecao de arquivos XML para o processamento.",cTitulo)
		EndIf
	Else
		MsgAlert("Realize a busca e selecao de arquivos XML para o processamento.",cTitulo)
	EndIf
	
	If lRet
		If len(aArq) > 0
	    	//tem que desabilitar este parametro momentaneamente (obrigatorio ter pedido de compra)
			lAtua := GetMV("MV_PCNFE")
	
			If lAtua
				PutMV("MV_PCNFE",.F.)
			Endif
	    	//***********************************************************//
	    	
	    	For I := 1 To len(aArq)
				cFile := lower(aArq[i][1])
				nPos  := aScan(aBrowse,{|x|  Alltrim(Upper(x[3]))==AllTrim(Upper(cFile))})
				cPath := If(!Empty(cPath),cPath,aBrowse[nPos][2])

				//Rotina de processamento do conteudo do arquivo XML
				MsAguarde({ || XMLNFE(cFile,nTipo) },"Processamento","Aguarde...")
				
				If !lErro
					aBrowse[nPos][1] := .F.
					aBrowse[nPos][4] := "Arquivo incluido com sucesso"
					aBrowse[nPos][5] := .F.
				Else
					aBrowse[nPos][1] := .F.
					aBrowse[nPos][4] := cErro
					aBrowse[nPos][5] := .F.
				EndIf
				
				If lErro 
					__CopyFile(cPath+cFile,cDirErros+cfile)
					FErase(cPath+cFile)	
				Else 
					//Apos processar arquivo, movo para lidos	
					__CopyFile(cPath+cFile,cDirLidos+cfile)
					FErase(cPath+cFile)
				EndIf	
				oBrowse:DrawSelect()
	    	Next I
	    	
	    	If lAtua
				PutMV("MV_PCNFE",.T.)
			Endif
	    Else
			MsgAlert("Nใo foi encontrado arquivo para processamento","Atencao!")
	    EndIf
	EndIf
Return(lRet)
	
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณXMLNFE    บAutor  ณMarcos                                   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณRotina que carrega arquivo XML para memoria, verifica dados บฑฑ
ฑฑบ          ณe no caso de divergencia alerta, se nao, importa para a UP2 บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
     
Static Function XMLNFE(cFile,nTipo)
Local nPos         := 0
Local lAchou       := .F.
Local lAchouA7     := .F.
Local lAchouProd   := .F.
Local cIdEnt       := ""
Local aFatura      := {}
Local aAux         := {}
Local nX           := 0
Local nCont        := {}
Local cCGCOr       := ""
Local cArquivo     := ""
Private lAchouPC   := .F.
Private lMarcou    := .F.
Private lDiverge   := .F.
Private oNFe       := {}

//Limpo variavel de erro
cErro       := ""
lErro       := .F.
lCritica    := .F.

Private nHdl      := fOpen(cPath+cFile,0)
Private aCamposPE := {}

//Erro ao Abrir arquivo XML
If nHdl == -1
	If !Empty(cFile)
		cErro := "O arquivo de nome "+cFile+" nao pode ser aberto!"
		lErro := .T.
	Endif
	Return(lErro)
Endif

nTamFile := fSeek(nHdl,0,2)
fSeek(nHdl,0,0)
cBuffer  := Space(nTamFile)                // Variavel para criacao da linha do registro para leitura
nBtLidos := fRead(nHdl,@cBuffer,nTamFile)  // Leitura  do arquivo XML
fClose(nHdl)

//tenho que jogar nesta variavel para nao tirar os acentos
cArquivo := cBuffer

nAt :=  At( '<', cBuffer) //Busco primeira tag
If nAt <> 1
	cBuffer := Stuff(cBuffer,0,nAt-1,'')
EndIf

//Retirar os acentos do arquivo XML
cTmpBuffer := FwNoAccent(cBuffer)
cBuffer    := Nil
cBuffer    := cTmpBuffer //Devolve conteudo do arquivo XML sem os acentos
cAviso     := ""
oNfe       := XmlParser(cBuffer,"_",@cAviso,@cErro)

//Caso nใo tenha interpretado o arquivo XML, retirar caracteres errados
If Valtype(oNfe)='U'
	cBuffer := StrTran(cBuffer, '?<?xml', '<?xml')
	cBuffer := StrTran(cBuffer, 'iปฟ', '')

        If AT('encoding',cBuffer) = 0 
    		cBuffer := '<?xml version="1.0" encoding="UTF-8"?>' + cBuffer
    	Endif

	oNfe := XmlParser(cBuffer,"_",@cAviso,@cErro)
EndIf

//Caso nใo tenha interpretado o arquivo XML, trocar codifica็ใo do arquivo
If Valtype(oNfe)='U'
	cBuffer := StrTran(cBuffer, 'encoding="UTF-8"', 'encoding="ISO-8859-1"')
	cBuffer := StrTran(cBuffer, 'encoding="utf-8"', 'encoding="iso-8859-1"')
	oNfe    := XmlParser(cBuffer,"_",@cAviso,@cErro)	
EndIf

Private oNF

// Procuro no XML qual o CFOP
Private cCFOP 
cCFOP := Substr(cBuffer,At("<CFOP>", cBuffer)+6,4)

nTipo := BuscaNatOp(cCFOP)

//Erro ao buscar tipo de operacao para arquivo XML
If nTipo == 0
	cErro := "Necessario cadastrar o tipo de XML para a natureza: " + cCFOP + "."
	lErro := .T.
	Return(lErro)
EndIf

If nTipo <> 4 //Quando o tipo de documento nใo for 4 (apenas 1(Normal), 2(Benef-Cliente), e 5(Benef-Fornec), validar se eh NFE 
	If Type("oNFe:_NfeProc")<> "U"
		oNF := oNFe:_NFeProc:_NFe
	ElseIf Type("oNFe:_ENVINFE")<> "U"   //Versao 3.1
		oNF := oNFe:_ENVINFE:_NFe
	ElseIf Type("oNFe")<> "U"
		oNF := oNFe:_NFe
	Else
		cErro := "XML nใo ้ um NFE "
		lErro := .T.
		Return(lErro)
	Endif
Else
	If XmlChildEx(oNFe, "_CTEPROC") != Nil
		If Type("oNFe:_CTEProc")<> "U"
			If U_XMLMA004(@cErro,cFile,,,oNFe:_CTEProc:_CTE,cPath,cArquivo,cCFOP)
				lErro := .F.
			Else
				//cErro := "Erro ao importar CTE."
				lErro := .T.
			EndIf
		Else
			cErro := "XML nใo ้ um CTE "
			lErro := .T.
		Endif
	ElseIf XmlChildEx(oNFe, "_PROCCTE") != Nil
	    If Type("oNFe:_PROCCTE")<> "U"
	   		If U_XMLMA004(@cErro,cFile,,,oNFe:_PROCCTE:_CTE,cPath,cArquivo,cCFOP)
				lErro := .F.
			Else
				lErro := .T.
			EndIf
		Else
			cErro := "XML nใo ้ um CTE "
			lErro := .T.
		Endif
	Else
		cErro := "XML nใo ้ um CTE "
		lErro := .T.
	Endif
	
	Return(lErro)
Endif

Private oEmitente  := oNF:_InfNfe:_Emit
Private oIdent     := oNF:_InfNfe:_IDE
Private oDestino   := oNF:_InfNfe:_Dest
Private oTotal     := oNF:_InfNfe:_Total
Private oTransp    := oNF:_InfNfe:_Transp
Private oDet       := oNF:_InfNfe:_Det
Private oICM

If lValidaNFE
	cIdEnt := GetIdEnt()
	
	If .not. Empty(cIdEnt)
		lErro := NFeChave(Right(AllTrim(oNF:_InfNfe:_Id:Text),44), cIdEnt)
		If lErro
			If empty(cErro)
				cErro := "Erro ao obter validar chave NFe. SEFAZ" 
			EndIf
			Return(lErro)
		EndIf
	Else
		cErro := "Erro ao obter Identifica็ใo para validar chave NFe." 
	    lErro := .T.
		Return(lErro)
	EndIf
EndIf 

If Type("oNF:_InfNfe:_ICMS")<> "U"
	oICM   := oNF:_InfNfe:_ICMS
Else
	oICM   := nil
Endif

Private oFatura    := IIf(Type("oNF:_InfNfe:_Cobr")=="U",Nil,oNF:_InfNfe)
Private cEdit1     := Space(TamSX3("B1_COD"    )[1])
Private _DESCdigit := Space(TamSX3("B1_DESC"   )[1])
Private _NCMdigit  := Space(TamSX3("B1_POSIPI" )[1])

oDet := IIf(ValType(oDet)=="O",{oDet},oDet)

// Valida็๕es -------------------------------
If nTipo = 1
	cTipo := "N"
ElseIF nTipo = 2
	cTipo := "B"
ElseIF nTipo = 3
	cTipo := "D"
ElseIF nTipo = 5
	cTipo := "R"
ElseIF nTipo = 6
	cTipo := "E"
EndIf

//vejo se a nota ้ para a empresa/filial logada
if !Empty(SM0->M0_CGC)
	cCGCOr := AllTrim(IIf(Type("oDestino:_CPF")=="U",oDestino:_CNPJ:TEXT,oDestino:_CPF:TEXT))
	IF SM0->M0_CGC <> cCGCOr
		cErro  := "Arquivo XML pertence a outra empresa/filial"
		lErro  := .T.
		Return(lErro)
	Endif 
Endif	

// CNPJ ou CPF
cCgc := AllTrim(IIf(Type("oEmitente:_CPF")=="U",oEmitente:_CNPJ:TEXT,oEmitente:_CPF:TEXT))

//vejo se ้ produto uso e consumo e se o parametro estแ preenchido e o produto valido.
If lChkCons .And. Empty(cProdSubst)
	cErro  := "Falta cadastrar o produto gen้rico no parโmetro XML_PRDGEN"
	lErro  := .T.
	Return(lErro)
ElseIf lChkCons                   
	//vejo se o produto existe
	dbSelectArea("SB1")
	If !SB1->(dbSetOrder(1),dbSeek(xFilial("SB1")+AllTrim(cProdSubst))) 
		cErro  := "Produto gen้rico " + AllTrim(cProdSubst) + " nใo encontrado no Protheus"
		lErro  := .T.
		Return(lErro)
	Endif
Endif

//Erro ao encontrar registro no protheus
If nTipo==1 .OR. nTipo==5  .OR. nTipo==6  // Nota Normal ou Beneficiamento ou remessa recebido de Fornecedor
	cQuery := ""
	cQuery += " SELECT SA2.A2_COD, SA2.A2_LOJA, SA2.A2_MSBLQL"
	cQuery += " FROM " + RetSqlName( "SA2" ) + " SA2 "
	cQuery += " WHERE SA2.A2_FILIAL = '" + xFilial("SA2")+ "' "
	cQuery += " AND SA2.A2_CGC = '"      + Alltrim(cCgc) + "' "
	cQuery += " AND SA2.D_E_L_E_T_ <> '*' "
	IIf(Select("TMPSA2") > 0, TMPSA2->(dbCloseArea()), Nil)
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPSA2",.T.,.T.)
	If TMPSA2->(Eof())	
		//Se nao encontrou o CNPJ
		cErro := "Fornecedor Nใo Localizado - Verifique " + cCgc
		lErro := .T.
		Return(lErro)
	Else
		//vejo senใo estแ bloqueado
		If AllTrim(TMPSA2->A2_MSBLQL) <> '2'
			cErro := "Fornecedor Bloqueado - Verifique " + cCgc
			lErro := .T.
			Return(lErro)
		Else
			//Consulto a sa2, para posicionar no registro correto
			SA2->(dbSetOrder(1), dbSeek(xFilial("SA2")+TMPSA2->A2_COD+TMPSA2->A2_LOJA))
		Endif
	Endif
	
	IIf(Select("TMPSA2") > 0, TMPSA2->(dbCloseArea()), Nil)
Else
	If !SA1->(dbSetOrder(3), dbSeek(xFilial("SA1")+cCgc))
		cErro := "Cliente Nใo Localizado - Verifique " + cCgc
		lErro := .T.
		Return(lErro)
	Endif
Endif

// -- Nota Fiscal jแ existe na base ?
If nTipo==1 .OR. nTipo==5 .OR. nTipo==6 // Nota Normal ou Beneficiamento ou remessa recebido de Fornecedor
	If SF1->(DbSeek(XFilial("SF1")+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+Padr(OIdent:_serie:TEXT,3)+SA2->A2_COD+SA2->A2_LOJA))
		cErro := "Nota: "+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+"/"+OIdent:_serie:TEXT+" do Fornec. "+SA2->A2_COD+"/"+SA2->A2_LOJA+" ja Importada."
		lErro := .T.
		Return(lErro)
	ElseIf UP2->(DbSeek(XFilial("UP2")+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+Padr(OIdent:_serie:TEXT,3)+SA2->A2_COD+SA2->A2_LOJA))
		While !UP2->(EOF()) .And. Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)==UP2->UP2_DOC .And. Padr(OIdent:_serie:TEXT,3)==UP2->UP2_SERIE .And.;
		       UP2->UP2_FORNEC==SA2->A2_COD .AND. UP2->UP2_LOJA==SA2->A2_LOJA .AND. !lAchou
			If Upper(Alltrim(UP2->UP2_REPROV)) == "S"
				UP2->(DbSkip())
			Else
				lAchou := .T.
			EndIF
		EndDo
		
		If lAchou 
			cErro := "Nota: "+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+"/"+OIdent:_serie:TEXT+" do Fornec. "+SA2->A2_COD+"/"+SA2->A2_LOJA+" ja Importada."
			lErro := .T.
			Return(lErro)
		EndIf
	EndIf
Else
	If SF1->(DbSeek(XFilial("SF1")+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+Padr(OIdent:_serie:TEXT,3)+SA1->A1_COD+SA1->A1_LOJA))
		cErro := "Nota: "+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+"/"+OIdent:_serie:TEXT+" do Cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" ja Importada."
		lErro := .T.
		Return(lErro)
	ElseIf	UP2->(DbSeek(XFilial("UP2")+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+Padr(OIdent:_serie:TEXT,3)+SA1->A1_COD+SA1->A1_LOJA))
		While !UP2->(EOF()) .And. Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)==UP2->UP2_DOC .And. Padr(OIdent:_serie:TEXT,3)==UP2->UP2_SERIE .And. ;
		       UP2->UP2_FORNEC==SA1->A1_COD .AND. UP2->UP2_LOJA==SA1->A1_LOJA .AND. !lAchou
			If Upper(Alltrim(UP2->UP2_REPROV)) == "S"
				UP2->(DbSkip())
			Else
				lAchou := .T.
			EndIF
		EndDo
		
		If lAchou 
			cErro := "Nota: "+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+"/"+OIdent:_serie:TEXT+" do Fornec. "+SA2->A2_COD+"/"+SA2->A2_LOJA+" ja Importada."
			lErro := .T.
			Return(lErro)
		EndIf
	Endif
EndIf 

aCabec := {}
aItens := {} 

aadd(aCabec,{"F1_TIPO"   ,If(nTipo==1,"N",If(nTipo==2,"B",If(nTipo==3,"D",If(nTipo==5,"R","E")))),Nil,Nil})
aadd(aCabec,{"F1_FORMUL" ,"N",Nil,Nil})
aadd(aCabec,{"F1_DOC"    ,Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9),Nil,Nil})
aadd(aCabec,{"F1_SERIE"  ,OIdent:_serie:TEXT,Nil,Nil})
aadd(aCabec,{"F1_CHVNFE" ,Right(AllTrim(oNF:_InfNfe:_ID:Text),44),NIL})

IF Type("oTransp:_VOL:_ESP")<> "U"  
	aadd(aCabec,{"F1_ESPECI1",AllTrim(oTransp:_VOL:_ESP:Text),NIL})
Endif  

IF Type("oTransp:_VOL:_QVOL")<> "U"
	aadd(aCabec,{"F1_VOLUME1",val(AllTrim(oTransp:_VOL:_QVOL:Text)),NIL})
Endif  

IF Type("oTransp:_VOL:_PESOL")<> "U"
	aadd(aCabec,{"F1_PLIQUI",val(AllTrim(oTransp:_VOL:_PESOL:Text)),NIL})
Endif

IF Type("oTransp:_VOL:_PESOB")<> "U"
	aadd(aCabec,{"F1_PBRUTO",val(AllTrim(oTransp:_VOL:_PESOB:Text)),NIL})
Endif

IF Type('oTransp:_Transporta:_CNPJ') <> 'U'  
	SA4->(dbSetOrder(3) )
    
    IF	SA4->(dbSeek(xFilial("SA4")+AllTrim(oTransp:_Transporta:_CNPJ:Text)))
		aadd(aCabec,{"F1_TRANSP",SA4->A4_COD,NIL})
	Endif
Endif

//Versao 3.1 possui tag diferente para data de emissao
If oNF:_InfNfe:_Versao:Text = "3.1"
	cData := Left(Alltrim(OIdent:_dhEmi:TEXT),10)
ElseIf Type("OIdent:_dEmi") <> "U" 
	cData := Alltrim(OIdent:_dEmi:TEXT)
Else
	cData := ""
EndIf
    
If cData <> ""
	dData := CTOD(Right(cData,2)+'/'+Substr(cData,6,2)+'/'+Left(cData,4))
Else
	//Caso nao exista nenhuma data, uso data do sistema
	dData := dDatabase
EndIf

aadd(aCabec,{"F1_EMISSAO",dData,Nil,Nil})
aadd(aCabec,{"F1_FORNECE",If(nTipo=1.or.nTipo=5.or.nTipo=6,SA2->A2_COD,SA1->A1_COD),Nil,Nil})
aadd(aCabec,{"F1_LOJA"   ,If(nTipo=1.or.nTipo=5.or.nTipo=6,SA2->A2_LOJA,SA1->A1_LOJA),Nil,Nil})
aadd(aCabec,{"F1_ESPECIE",cTipoEspec,Nil,Nil})

//Valor para registro de critica S/N
aadd(aCabec,{"UP2_CRITIC","N",Nil,Nil})

//Valor totalizador dos impostos
aadd(aCabec,{"UP2_BASE",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VBC:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VICMS",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VICMS:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_BCST",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VBCST:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VST",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VST:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VTOTAL",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VPROD:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VFRETE",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VFRETE:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VSEGUR",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VSEG:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VDESC",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VDESC:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VII",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VII:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VIPI",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VIPI:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VPIS",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VPIS:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VCOFIN",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VCOFINS:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VOUTRO",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VOUTRO:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_VNF",Val(oNF:_INFNFE:_TOTAL:_ICMSTOT:_VNF:TEXT),Nil,Nil})
aadd(aCabec,{"UP2_NOME",If(nTipo=1.or.nTipo=5.or.nTipo=6,POSICIONE("SA2",1,XFILIAL("SA2")+SA2->A2_COD+SA2->A2_LOJA,"SA2->A2_NOME"),POSICIONE("SA1",1,XFILIAL("SA1")+SA1->A1_COD+SA1->A1_LOJA,"SA1->A1_NOME")),Nil,Nil})              
aadd(aCabec,{"UP2_ARQXML",cArquivo,Nil,Nil})

Private aProduto   := {} //{"Cod. Prod. Protheus","Cod. prod. Fornecedor"}
Private aProdCods  := {} //{"Cod. Prod. Protheus","Cod. prod. Fornecedor"}

For nX := 1 To Len(oDet)
	cEdit1     := Space(TamSX3("B1_COD"    )[1])
	_DESCdigit := Space(TamSX3("B1_DESC"   )[1])
	_NCMdigit  := Space(TamSX3("B1_POSIPI" )[1])
	cProduto   := AllTrim(oDet[nX]:_Prod:_cProd:TEXT) // tenho que manter o mesmo padrao do campo da sa5/sa7
	xProduto   := cProduto
	
	cNCM:=IIF(Type("oDet["+CvalToChar(nX)+"]:_Prod:_NCM")=="U",space(12),oDet[nX]:_Prod:_NCM:TEXT)
	Chkproc=.F.
	
	If nTipo=1 .OR. nTipo=5 .OR. nTipo=6   
		//Tratamento de Nota de entrada Normal, exceto notas de bens de consumo e transferencia entre filiais
		If !lChkCons .Or. lChkTrans
			cQuery := ""
			cQuery += " SELECT SA5.A5_FILIAL, SA5.A5_PRODUTO, SA5.A5_CODPRF, SA5.A5_FORNECE, SA5.A5_LOJA "
			cQuery += " FROM " + RetSqlName( "SA5" ) + " SA5 "
			cQuery += " WHERE SA5.A5_FILIAL = '"  + xFilial("SA5")        + "' "
			cQuery += " AND SA5.A5_FORNECE = '" + Alltrim(SA2->A2_COD)  + "' "
			cQuery += " AND SA5.A5_LOJA = '"    + Alltrim(SA2->A2_LOJA) + "' "
			cQuery += " AND SA5.A5_CODPRF = '"  + AllTrim(cProduto)     + "' "
			cQuery += " AND SA5.A5_PRODUTO <> ' '"
			cQuery += " AND SA5.D_E_L_E_T_ <> '*' "
	
     		IIf(Select("TMPSA5") > 0, TMPSA5->(dbCloseArea()), Nil)

			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMPSA5",.T.,.T.)
			TMPSA5->(DbGoTop())			
			//Se nใo localizado o produto na tabela, solicito do codigo substituto
			If (Alltrim(TMPSA5->A5_CODPRF) <> Alltrim(cProduto))
				If !MsgYesNo("Produto Cod.: "+cProduto+" Nao Encontrado. Digita Codigo Protheus?")
					cErro := "Produto Cod.: "+cProduto+" Nao Encontrado."
					lErro := .T.
					Return(lErro)
				Endif
				
				DigCodSubs(Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9),Padr(OIdent:_serie:TEXT,3),nX)
	
				//Atualizacao do cadastro de Produto/Fornecedor
				If Chkproc!=.T.
					cErro := "Produto Cod.: "+cProduto+" Nao Encontrado."
					lErro := .T.
					Return(lErro)
				Else
					If SA5->(dbSetOrder(1), dbSeek(xFilial("SA5")+SA2->A2_COD+SA2->A2_LOJA+SB1->B1_COD))
						RecLock("SA5",.F.)
					Else
						Reclock("SA5",.T.)
					Endif
					
					SA5->A5_FILIAL  := xFilial("SA5")
					SA5->A5_FORNECE := SA2->A2_COD
					SA5->A5_LOJA    := SA2->A2_LOJA
					SA5->A5_NOMEFOR := SA2->A2_NOME
					SA5->A5_PRODUTO := SB1->B1_COD
					SA5->A5_NOMPROD := oDet[nX]:_Prod:_xProd:TEXT
					SA5->A5_CODPRF  := xProduto 
					SA5->(MsUnlock())
				EndIf
				
			//Caso localizado o produto, realiza alteracao no cadastro de produtos dependendo do parametro
			Else
				SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+TMPSA5->A5_PRODUTO))
				
				If lNCM
					if .not. SB1->(EOF())
						If !Empty(cNCM) .and. cNCM != '00000000' .And. SB1->B1_POSIPI <> cNCM
							RecLock("SB1",.F.)
							Replace B1_POSIPI with cNCM
							MSUnLock()
						Endif
					Endif	
				Endif
			EndIf
			
			IIf(Select("TMPSA5") > 0, TMPSA5->(dbCloseArea()), Nil)
			
		ElseIf lChkCons
			If Empty(cProdSubst)
				DigCodSubs(Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9),Padr(OIdent:_serie:TEXT,3),nX)
				
				If Chkproc!=.T.
					cErro := "Produto Cod.: "+cProduto+" Nao Encontrado."
					lErro := .T.
					Return(lErro)
				Else
					aAdd(aProduto,{ cProduto, xProduto})
				EndIf
			Else
				aAdd(aProduto,{ cProdSubst, xProduto})
			EndIf
		EndIf
	Else
		lAchouA7 := .F.
		lAchouProd := .F.
		
		dbSelectArea("SA7")
		dbSetOrder(1)   // FILIAL + CLIENTE + LOJA + PRODUTO
		SA7->(DbGoTop())
		lAchouA7 := dbSeek(xFilial("SA7")+SA1->A1_COD+SA1->A1_LOJA)
		
		//Se encontrou o cliente
		if lAchouA7
			while (.not. SA7->(EOF())) .AND. (SA7->A7_CLIENTE==SA1->A1_COD) .and. (SA7->A7_LOJA==SA1->A1_LOJA)
				if (SA7->A7_CLIENTE==SA1->A1_COD) .And. (SA7->A7_LOJA==SA1->A1_LOJA) .And. (Alltrim(SA7->A7_CODCLI)==Alltrim(cProduto))
					lAchouProd := .T.
					exit				
				endIf
				SA7->(dbSkip())
			endDo
		endIf
		
		//Se nao achou o cliente ou o produto, iraด incluir
		if !lAchouA7 .Or. !lAchouProd
			If !MsgYesNo ("Produto Cod.: "+cProduto+" Nao Encontrado. Digita Codigo Protheus?")
				cErro := "Produto Cod.: "+cProduto+" Nao Encontrado."
				lErro := .T.
				Return(lErro)
			endIf
			
			DigCodSubs(Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9),Padr(OIdent:_serie:TEXT,3),nX)
			
			If Chkproc!=.T.
				cErro := "Produto Cod.: "+cProduto+" Nao Encontrado."
				lErro := .T.
				Return(lErro)
			Else
				//caso o produto do protheus exista, sem o codigo do cliente, faz alteracao, se nao, inclusao
				If SA7->(dbSetOrder(1), dbSeek(xFilial("SA7")+SA1->A1_COD+SA1->A1_LOJA+SB1->B1_COD))
					RecLock("SA7",.F.)
				Else
					Reclock("SA7",.T.)
				Endif
				
				SA7->A7_FILIAL  := xFilial("SA7")
				SA7->A7_CLIENTE := SA1->A1_COD
				SA7->A7_LOJA    := SA1->A1_LOJA
				SA7->A7_DESCCLI := oDet[nX]:_Prod:_xProd:TEXT
				SA7->A7_PRODUTO := SB1->B1_COD
				SA7->A7_CODCLI  := xProduto
				SA7->(MsUnlock())		
			EndIf

		//Quando localizado produto na tabela cliente X produto realizo operacao na tabela de produtos
		ElseIf SA7->A7_CLIENTE==SA1->A1_COD .AND. SA7->A7_LOJA==SA1->A1_LOJA .AND. AllTrim(SA7->A7_CODCLI)==Alltrim(cProduto)
			SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+SA7->A7_PRODUTO))
			if .not. SB1->(EOF()) .And. lNCM
				If !Empty(cNCM) .and. cNCM != '00000000' .And. SB1->B1_POSIPI <> cNCM 
					RecLock("SB1",.F.)
					Replace B1_POSIPI with cNCM
					MSUnLock()
				endif
			Endif
		Endif 
	Endif
	
	SB1->(dbSetOrder(1))
    
    //atribuo o codigo do protudo do Protheus e do Fornecedor para referencias
 	aAdd(aProdCods,{ ALLTRIM(SB1->B1_COD), Alltrim(xProduto)}) //{"Cod. Prod. Protheus","Cod. prod. Fornecedor"}
Next nX

//Montagem de array com informacoes dos itens buscando informacoes dos produtos existentes no protheus
For nX := 1 To Len(oDet)
 	aLinha  := {}
	cProduto:= AllTrim(oDet[nX]:_Prod:_cProd:TEXT)
	xProduto:= cProduto
	
	cNCM:=IIF(Type("oDet["+CvalToChar(nX)+"]:_Prod:_NCM")=="U",space(12),oDet[nX]:_Prod:_NCM:TEXT)
	Chkproc=.F.
	
	If nTipo=1 .or. nTipo=5 .OR. nTipo=6  .And. !lChkCons
		dbSelectArea("SA5")
		dbSetOrder(5)                  // FILIAL + CODIGO PRODUTO NO FORNECEDOR
		dbSeek(xFilial("SA5") + PadR(cProduto,TamSX3("A5_CODPRF")[1]) )

		//Produto existe por ser incluido anteriormente, posiciono nele para consultar tabela de produtos
		While !SA5->(EOF()) .AND. Alltrim(SA5->A5_CODPRF) == Alltrim(cProduto) .AND. SA5->A5_FORNECE <> SA2->A2_COD .AND. SA5->A5_LOJA <> SA2->A2_LOJA
			SA5->(dbSkip())
		End

		SB1->(dbSetOrder(1) , dbSeek(xFilial("SB1")+SA5->A5_PRODUTO))
	ElseIf nTipo == 1 .And. lChkCons
		
		SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+cProdSubst))
	Else
		dbSelectArea("SA7")
		dbSetOrder(1)   // FILIAL + CLIENTE + LOJA + PRODUTO
		dbSeek(xFilial("SA7")+SA1->A1_COD+SA1->A1_LOJA)
		
		//Produto existe por ser incluido anteriormente, posiciono nele para consultar tabela de produtos
		While !SA7->(EOF()) .AND. Alltrim(SA7->A7_CODCLI) <> AllTrim(cProduto) .AND. SA7->A7_CLIENTE <> SA1->A1_COD .AND. SA7->A7_LOJA <> SA1->A1_LOJA
			SA5->(dbSkip())
		End

		SB1->(dbSetOrder(1) , dbSeek(xFilial("SB1")+SA7->A7_PRODUTO))
	Endif

	// Posiciono novamente usando o array aProdCods para achar o produto no protheus
	If nTipo == 1 .And. lChkCons
		SB1->(dbSetOrder(1) , dbSeek(xFilial("SB1")+AllTrim(cProdSubst))) 
	Else
		SB1->(dbSetOrder(1) , dbSeek(xFilial("SB1")+aProdCods[nX][1]))
	Endif
	
	aadd(aLinha,{"D1_COD",SB1->B1_COD,Nil,Nil})
	aadd(aLinha,{"D1_DESC",SB1->B1_DESC,Nil,Nil})
	 
	If Val(oDet[nX]:_Prod:_qCom:TEXT) != 0
		aadd(aLinha,{"D1_QUANT",Val(oDet[nX]:_Prod:_qCom:TEXT),Nil,Nil})
		aadd(aLinha,{"D1_VUNIT",Round(Val(oDet[nX]:_Prod:_vProd:TEXT)/Val(oDet[nX]:_Prod:_qCom:TEXT),6),Nil,Nil})
	ElseIf Val(oDet[nX]:_Prod:_qTrib:TEXT) != 0
		aadd(aLinha,{"D1_QUANT",Val(oDet[nX]:_Prod:_qTrib:TEXT),Nil,Nil})
		aadd(aLinha,{"D1_VUNIT",Round(Val(oDet[nX]:_Prod:_vProd:TEXT)/Val(oDet[nX]:_Prod:_qTrib:TEXT),6),Nil,Nil})
	Else
		cErro := "Produto: "+cProduto+" no XML com quantidade igual a zero."
		lErro := .T.
	    Return()
	Endif
	
    //Valor do rateio do frete para cliente informado
	nQtdItem  := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_QUANT"}),2]
	aadd(aLinha,{"UP3_RATEIO",0,Nil,Nil}) //Rateio do frete
	
	nValorUnit := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_VUNIT"}),2]
	If Type("oDet["+CvalToChar(nX)+"]:_IMPOSTO:_IPI:_IPITRIB:_VIPI") == "U" 
		nValorIpi := 0
	Else
		nValorIpi := Val(oDet[nX]:_IMPOSTO:_IPI:_IPITRIB:_VIPI:TEXT)/ nQtdItem
	EndIF
	
	nTotalImp := (nValorUnit+nValorIpi) * nQtdItem
	
	aadd(aLinha,{"UP3_TOTIMP",nTotalImp,Nil,Nil})	// Total com impostos
	aadd(aLinha,{"D1_TOTAL",Val(oDet[nX]:_Prod:_vProd:TEXT),Nil,Nil})
	
	_cfop:=oDet[nX]:_Prod:_CFOP:TEXT
	aAdd(aLinha,{"UP3_CFOP",_cfop,Nil,Nil})
	
	If Type("oDet["+CvalToChar(nX)+"]:_Prod:_vDesc")<> "U"
		aadd(aLinha,{"D1_VALDESC",Val(oDet[nX]:_Prod:_vDesc:TEXT),Nil,Nil})
	Else
		aadd(aLinha,{"D1_VALDESC",0,Nil,Nil})		
	Endif
	
	Do Case
		Case Type("oDet["+CvalToChar(nX)+"]:_Imposto:_ICMS:_ICMS00")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS00
		Case Type("oDet["+CvalToChar(nX)+"]:_Imposto:_ICMS:_ICMS10")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS10
		Case Type("oDet["+CvalToChar(nX)+"]:_Imposto:_ICMS:_ICMS20")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS20
		Case Type("oDet["+CvalToChar(nX)+"]:_Imposto:_ICMS:_ICMS30")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS30
		Case Type("oDet["+CvalToChar(nX)+"]:_Imposto:_ICMS:_ICMS40")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS40
		Case Type("oDet["+CvalToChar(nX)+"]:_Imposto:_ICMS:_ICMS51")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS51
		Case Type("oDet["+CvalToChar(nX)+"]:_Imposto:_ICMS:_ICMS60")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS60
		Case Type("oDet["+CvalToChar(nX)+"]:_Imposto:_ICMS:_ICMS70")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS70
		Case Type("oDet["+CvalToChar(nX)+"]:_Imposto:_ICMS:_ICMS90")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS90
	EndCase
	
	If Type("oICM:_orig") == "U" .Or. Type("oICM:_CST") == "U"
		CST_Aux:='000'
	Else
		CST_Aux:=Alltrim(oICM:_orig:TEXT)+Alltrim(oICM:_CST:TEXT)	
	EndIf
	
	aadd(aLinha,{"D1_CLASFIS",CST_Aux,Nil,Nil})
	aAdd(aLinha,{"UP3_CRITIC",Space(250),Nil,Nil})
	aAdd(aLinha,{"UP3_NCM",cNCM,Nil,Nil})

	If Type("oICM:_VICMS") == "U" 
		aAdd(aLinha,{"UP3_VICMS",0,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_VICMS",Val(oICM:_VICMS:TEXT),Nil,Nil})
	EndIF

	If Type("oICM:_PICMS") == "U" 
		aAdd(aLinha,{"UP3_PICMS",0,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_PICMS",Val(oICM:_PICMS:TEXT),Nil,Nil})
	EndiF
	
	If Type("oDet["+CvalToChar(nX)+"]:_IMPOSTO:_IPI:_IPITRIB:_VIPI") == "U" 
		aAdd(aLinha,{"UP3_VIPI",0,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_VIPI",Val(oDet[nX]:_IMPOSTO:_IPI:_IPITRIB:_VIPI:TEXT),Nil,Nil})
	EndIF
	
	If Type("oDet["+CvalToChar(nX)+"]:_IMPOSTO:_IPI:_IPITRIB:_PIPI") == "U"
		aAdd(aLinha,{"UP3_PIPI",0,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_PIPI",Val(oDet[nX]:_IMPOSTO:_IPI:_IPITRIB:_PIPI:TEXT),Nil,Nil})
	EndIF
	
	If Type("oDet["+CvalToChar(nX)+"]:_IMPOSTO:_PIS:_PISALIQ:_VPIS") == "U"
		aAdd(aLinha,{"UP3_VPIS",0,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_VPIS",Val(oDet[nX]:_IMPOSTO:_PIS:_PISALIQ:_VPIS:TEXT),Nil,Nil})
	EndIF

	If Type("oDet["+CvalToChar(nX)+"]:_IMPOSTO:_PIS:_PISALIQ:_PPIS") == "U"
		aAdd(aLinha,{"UP3_PPIS",0,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_PPIS",Val(oDet[nX]:_IMPOSTO:_PIS:_PISALIQ:_PPIS:TEXT),Nil,Nil})
	EndIf
	
	If Type("oDet["+CvalToChar(nX)+"]:_IMPOSTO:_COFINS:_COFINSALIQ:_VCOFINS") == "U"
		aAdd(aLinha,{"UP3_VCOFIN",0,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_VCOFIN",Val(oDet[nX]:_IMPOSTO:_COFINS:_COFINSALIQ:_VCOFINS:TEXT),Nil,Nil})
	EndIF
	
	If Type("oDet["+CvalToChar(nX)+"]:_IMPOSTO:_COFINS:_COFINSALIQ:_PCOFINS") == "U"
		aAdd(aLinha,{"UP3_PCOFIN",0,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_PCOFIN",Val(oDet[nX]:_IMPOSTO:_COFINS:_COFINSALIQ:_PCOFINS:TEXT),Nil,Nil})
	EndIF

	cNumPedido := ""
	cPedItem   := ""
	
	//Caso tenha o numero do pedido por item, vou consultar de novo o pedido para aquele item
	If lCpoxPed
		If Type("oNfe:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_XPED") <> "U"                          //somente 1 item na NF
			cNumPedido := oNfe:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_XPED:TEXT		
		ElseIf Type("oNfe:_NFEPROC:_NFE:_INFNFE:_DET["+cValToChar(nX)+"]:_PROD:_XPED") <> "U"  //mais do que 1 item vira um array
			cNumPedido := oNfe:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD:_XPED:TEXT
		Endif
				
		If !Empty(cNumPedido)
			cQuery := ""
			cQuery += " SELECT C7_NUM T9_PEDIDO,"
			cQuery += " C7_ITEM T9_ITEM,"
			cQuery += " C7_PRODUTO T9_PRODUTO,"
			cQuery += " B1_DESC T9_DESC,"
			cQuery += " B1_UM T9_UM,"
			cQuery += " C7_QUANT-C7_QUJE T9_QTDE," //Qtd solicitada - Qtd ja Entregue
			cQuery += " C7_PRECO T9_UNIT,"
			cQuery += " C7_TOTAL T9_TOTAL,"
			cQuery += " C7_DATPRF T9_DTPRV,"
			cQuery += " C7_LOCAL T9_ALMOX,"
			cQuery += " C7_OBS T9_OBSERV,"
			cQuery += " C7_CC T9_CCUSTO,"
			cQuery += " SC7.R_E_C_N_O_ T9_REG"
			cQuery += " FROM " + RetSqlName("SC7") + " SC7, " + RetSqlName("SB1") + " SB1 "
			cQuery += " WHERE C7_FILIAL = '" + xFilial("SC7") + "' "
			cQuery += " AND B1_FILIAL = '" + xFilial("SB1") + "' "
			cQuery += " AND SC7.D_E_L_E_T_ <> '*' "
			cQuery += " AND SB1.D_E_L_E_T_ <> '*' "
			cQuery += " AND C7_QUANT > C7_QUJE  "
			cQuery += " AND C7_RESIDUO = ' '  "
			cQuery += " AND C7_ENCER = ' ' "                           
			cQuery += " AND C7_NUM = '"  + cNumPedido +"'"
			cQuery += " AND C7_PRODUTO = B1_COD "
			cQuery += " AND C7_PRODUTO = '"+SB1->B1_COD+"'"
			
			//somente pedidos de compra liberados
			If lPCLib
				cQuery += " AND C7_CONAPRO = 'L'"
			Endif
			
			cQuery += " ORDER BY C7_NUM, C7_ITEM, C7_PRODUTO "
		
			IIf(Select("TMP") > 0, TMP->(dbCloseArea()), Nil)
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TMP",.T.,.T.)
		
			If !TMP->(EOF())
				cNumPedido := TMP->T9_PEDIDO
				cPedItem   := TMP->T9_ITEM
 
	 			aAdd(aLinha,{"UP3_STCRIT","S",Nil,Nil})
				aadd(aLinha,{"D1_PEDIDO",cNumPedido,Nil,Nil})
     			aadd(aLinha,{"D1_ITEMPC",cPedItem,Nil,Nil})
			Else
				aadd(aLinha,{"D1_PEDIDO","",Nil,Nil})
     			aadd(aLinha,{"D1_ITEMPC","",Nil,Nil})
				aAdd(aLinha,{"UP3_STCRIT","S",Nil,Nil})
			EndIf
		Else
			aadd(aLinha,{"D1_PEDIDO","",Nil,Nil})
   			aadd(aLinha,{"D1_ITEMPC","",Nil,Nil})
			aAdd(aLinha,{"UP3_STCRIT","S",Nil,Nil})
		Endif	
	Else
		aadd(aLinha,{"D1_PEDIDO","",Nil,Nil})
   		aadd(aLinha,{"D1_ITEMPC","",Nil,Nil})
		aAdd(aLinha,{"UP3_STCRIT","N",Nil,Nil})	
	EndIf
	
	If Type("oDet["+CvalToChar(nX)+"]:_PROD:_UCOM") == "U"
		aAdd(aLinha,{"UP3_UNCOM",SB1->B1_UM,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_UNCOM",SubStr(Alltrim(oDet[nX]:_PROD:_UCOM:TEXT),1,TamSX3("B1_UM")[1]),Nil,Nil})
	EndIf
		
	If Type("oDet["+CvalToChar(nX)+"]:_PROD:_UTRIB") == "U"
		aAdd(aLinha,{"UP3_UNTRIB",SB1->B1_UM,Nil,Nil})
	Else
		aAdd(aLinha,{"UP3_UNTRIB",SubStr(Alltrim(oDet[nX]:_PROD:_UCOM:TEXT),1,TamSX3("B1_UM")[1]),Nil,Nil})
	EndIf

	aadd(aItens,aLinha)
Next nX
	
If !lErro
	Begin Transaction
		IncPreNota(aCabec,aItens,aFatura)
	End Transaction
Endif  
Return


Static Function IncPreNota(aCabec,aItens,aFatura)
  Local nCont       := 0
  Local aArea       := GetArea()
  Local aAreaUP2    := GetArea("UP2")
  Local aAreaUP3    := GetArea("UP3")
  Local aAreaUPX    := ""
  Local lRet        := .F.
  Local nI          := 0
  Local nRECNOPAI   := 0
  Local cQuery      := ""
  Local cDoc        := ""
  Local cSer        := ""
  Local cForn       := ""
  Local cLj         := ""
                       
  //Inclusao do Cabecalho
  DbSelectArea("UP2")
  UP2->(DbSetOrder(1))
  UP2->(DbGoTop())
  
  RecLock("UP2",.T.)
  UP2->UP2_FILIAL := xFilial("UP2")
  UP2->UP2_TIPO   := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_TIPO"})   ,2]
  UP2->UP2_FORMUL := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_FORMUL"}) ,2]
  UP2->UP2_DOC    := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_DOC"})    ,2]
  UP2->UP2_SERIE  := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_SERIE"})  ,2]
  UP2->UP2_CHVNFE := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_CHVNFE"}) ,2]

  If ascan(aCabec,{|x| Alltrim(x[1])=="F1_ESPECI1"}) > 0
      UP2->UP2_ESPEC1 := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_ESPECI1"}),2]
  EndIf
  
  If ascan(aCabec,{|x| Alltrim(x[1])=="F1_VOLUME1"}) > 0
      UP2->UP2_VOLUME := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_VOLUME1"}),2]
  EndIf
  
  If ascan(aCabec,{|x| Alltrim(x[1])=="F1_PLIQUI"}) > 0
      UP2->UP2_PLIQUI := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_PLIQUI"}) ,2]
  EndIf
  
  If ascan(aCabec,{|x| Alltrim(x[1])=="F1_PBRUTO"}) > 0
      UP2->UP2_PBRUTO := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_PBRUTO"}) ,2]
  EndIf

  UP2->UP2_EMISSA := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_EMISSAO"}),2]

  If ascan(aCabec,{|x| Alltrim(x[1])=="F1_TRANSP"}) > 0
      UP2->UP2_TRANSP := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_TRANSP"}) ,2]
  EndIf
  
  UP2->UP2_FORNEC := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_FORNECE"}),2]
  UP2->UP2_LOJA   := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_LOJA"})   ,2]
  UP2->UP2_ESPECI := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_ESPECIE"}),2]
  UP2->UP2_CRITIC := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_CRITIC"}),2]
  UP2->UP2_NOME   := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_NOME"})  ,2]
  UP2->UP2_ARQXML := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_ARQXML"}),2]
  UP2->UP2_ESPEC1 := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_ESPECIE"}),2]

  //Informacoes de impostos do cabecalho
  UP2->UP2_BASE   := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_BASE"})   ,2]
  UP2->UP2_VICMS  := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VICMS"})  ,2]
  UP2->UP2_BCST   := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_BCST"})   ,2]
  UP2->UP2_VST    := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VST"})    ,2]
  UP2->UP2_VTOTAL := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VTOTAL"}),2]
  UP2->UP2_VFRETE := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VFRETE"}),2]

  UP2->UP2_VSEGUR := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VSEGUR"}),2]
  UP2->UP2_VDESC  := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VDESC"}) ,2]
  UP2->UP2_VII    := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VII"})   ,2]
  UP2->UP2_VIPI   := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VIPI"})  ,2]
  UP2->UP2_VPIS   := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VPIS"})  ,2]
  UP2->UP2_VCOFIN := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VCOFIN"}),2]
  UP2->UP2_VOUTRO := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VOUTRO"}),2]
  UP2->UP2_VNF    := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="UP2_VNF"})   ,2]

  If lNFAut 
      UP2->UP2_STATUS := "P"  //automatico direto para o Protheus
      UP2->UP2_PROCES := "S"
  ElseIf !lCpoxPed .Or. lChkTrans .Or. UP2->UP2_TIPO == 'E'
      UP2->UP2_STATUS := "F"  //envia direto para o fisico
      UP2->UP2_PROCES := "N"
  Else
  	  UP2->UP2_STATUS := "C"  //O documento de pre nota sempre serแ enviado para o comercial para conferencia
  	  UP2->UP2_PROCES := "N"
  Endif	
 
  // Caso compra de itens de consumo, nao busco pedido de compra
  If lChkCons .And. aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_TIPO"}),2]=="N" .And. !lChkTrans
      UP2->UP2_CONSUM := "S"
  // Caso Transferencia entre filiais, nao busco pedido de compra
  ElseIf aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_TIPO"}),2]=="N" .And. lChkTrans
      UP2->UP2_CONSUM := "T"
  Else
      UP2->UP2_CONSUM := "N"
  EndIf

  //Informacoes do usuario e hora de processamento
  UP2->UP2_USER := RetCodUsr()
  UP2->UP2_DATA := Date()
  UP2->UP2_HORA := Time()
  UP2->(MsUnlock())
  nRECNOPAI := UP2->(Recno())

  //Inclusao dos Itens
  For nCont := 1 to len(aItens)
    //Separo itens em linha
    aLinha     := aItens[nCont]

    DbSelectArea("UP3")
    UP3->(DbSetOrder(1))
    UP3->(DbGoTop())
    RecLock("UP3",.T.)
    
    UP3->UP3_FILIAL := xFilial("UP3")  //Para nao criar campo novo para registro da sequencia, e ficar sem historico em itens ja importados
    UP3->UP3_SEQ    := StrZero(nCont,3)// Marcos disse para usar o campo nao utilizado para registrar a sequencia do item
    UP3->UP3_DOC    := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_DOC"})    ,2]
    UP3->UP3_SERIE  := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_SERIE"})  ,2]
    UP3->UP3_EMISSA := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_EMISSAO"}),2]
    UP3->UP3_FORNEC := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_FORNECE"}),2]
    UP3->UP3_LOJA   := aCabec[ascan(aCabec,{|x| Alltrim(x[1])=="F1_LOJA"})   ,2]
    UP3->UP3_COD    := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_COD"})    ,2]
    UP3->UP3_DESCR  := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_DESC"})   ,2]
    UP3->UP3_QUANT  := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_QUANT"})  ,2]
    UP3->UP3_VUNIT  := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_VUNIT"})  ,2]
    UP3->UP3_TOTAL  := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_TOTAL"})  ,2]
    UP3->UP3_CRITIC := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_CRITIC"}),2]
    UP3->UP3_CFOP   := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_CFOP"})  ,2]   
    UP3->UP3_STCRIT := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_STCRIT"}),2]     

    //Informacoes de impostos dos itens
    UP3->UP3_NCM    := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_NCM"})   ,2]
    UP3->UP3_VICMS  := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_VICMS"}) ,2]
    UP3->UP3_PICMS  := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_PICMS"}) ,2]
    UP3->UP3_VIPI   := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_VIPI"})  ,2]
    UP3->UP3_PIPI   := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_PIPI"})  ,2]
    UP3->UP3_VPIS   := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_VPIS"})  ,2]
    UP3->UP3_PPIS   := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_PPIS"})  ,2]
    UP3->UP3_VCOFIN := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_VCOFIN"}),2]
    UP3->UP3_PCOFIN := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_PCOFIN"}),2]
    
    UP3->UP3_RATEIO := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_RATEIO"}),2]
    UP3->UP3_TOTIMP := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_TOTIMP"}),2]
    
    If ascan(aLinha,{|x| Alltrim(x[1])=="D1_PEDIDO"}) <> 0
		UP3->UP3_PEDIDO := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_PEDIDO"}),2]
	EndIf
	
    If ascan(aLinha,{|x| Alltrim(x[1])=="D1_ITEMPC"}) <> 0
		UP3->UP3_ITEMPC := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_ITEMPC"}),2]
	EndIf

    If ascan(aLinha,{|x| Alltrim(x[1])=="UP3_UNCOM"}) <> 0
		UP3->UP3_UNCOM := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_UNCOM"}),2]
	EndIf
		
    If ascan(aLinha,{|x| Alltrim(x[1])=="UP3_UNTRIB"}) <> 0
		UP3->UP3_UNTRIB := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="UP3_UNTRIB"}),2]
	EndIf

    //Informacoes do usuario e hora de processamento
    UP3->UP3_USER  := RetCodUsr()
    UP3->UP3_DATA  := Date()
    UP3->UP3_HORA  := Time()

    If ascan(aLinha,{|x| Alltrim(x[1])=="D1_VALDESC"}) >0
    	UP3->UP3_VALDES := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_VALDESC"}),2]
    EndIf

    UP3->UP3_CLASFI := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_CLASFIS"}),2]

    If ascan(aLinha,{|x| Alltrim(x[1])=="D1_PEDIDO"}) > 0
        UP3->UP3_PEDIDO := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_PEDIDO"}),2]
    EndIf

    If ascan(aLinha,{|x| Alltrim(x[1])=="D1_ITEMPC"}) > 0
        UP3->UP3_ITEMPC := aLinha[ascan(aLinha,{|x| Alltrim(x[1])=="D1_ITEMPC"}),2]
    EndIf

    //Recno Do cabecalho
    UP3->UP3_ID_PAI := nRECNOPAI
    UP3->(MsUnlock())
  Next

  //se o paraemtro estiver ativo tem que gerar a prenota automaticamente
  If lNFAut
       u_Prt05Ex("UP2",,1)
  Endif
  
  RestArea(aAreaUP3)
  RestArea(aAreaUP2)
  RestArea(aArea)
Return 


Static Function C(nTam)
Local nHRes := oMainWnd:nClientWidth     	// Resolucao horizontal do monitor

If nHRes == 640	                            // Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)
	nTam *= 0.8
 ElseIf (nHRes == 798).Or.(nHRes == 800)	// Resolucao 800x600
	nTam *= 1
Else	                                    // Resolucao 1024x768 e acima
	nTam *= 1.28
EndIf

//ณTratamento para tema "Flat"ณ
If "MP8" $ oApp:cVersion
	If (Alltrim(GetTheme()) == "FLAT") .Or. SetMdiChild()
		nTam *= 0.90
	EndIf
EndIf
Return Int(nTam)


Static Function ValProd()
Local aArea := GetArea()
Local lRet  := .F.

If !empty(cEdit1)
	dbSelectArea( "SB1" )
	dbSetOrder(1)		
	If dbSeek(xFilial("SB1")+cEdit1)
		lRet:= .T.
		_DESCdigit := SB1->B1_DESC
		_NCMdigit  := SB1->B1_POSIPI
	Else
		_DESCdigit := ''
		_NCMdigit  := ''    
 	
	  	MsgAlert("Produto "+AllTrim(cEdit1)+" nใo encontrado. Digite c๓digo de produto Protheus vแlido","Aten็ใo")
	EndIf
EndIf

RestArea(aArea)
Return lRet


Static Function Troca()
Chkproc=.T.
cProduto=cEdit1

dbSelectArea( "SB1" )
dbSetOrder(1)		
dbSeek(xFilial("SB1")+cEdit1)

If (SB1->B1_COD==cProduto) .AND. (!SB1->(EOF()))
	If Empty(SB1->B1_POSIPI) .and. !Empty(cNCM) .and. cNCM != '00000000' .And. lNCM //alterar o ncm se houver discrepancia
		RecLock("SB1",.F.)
		Replace B1_POSIPI with cNCM
		MSUnLock()
	Endif
	_oDlg:End()
Endif
Return


Static Function Cria_Dir(cDiretorio) 
	Local nRet := MakeDir(cDiretorio)

	If nRet != 0 
		MsgAlert("Nใo foi possํvel criar o diret๓rio. Erro: " + cValToChar( FError() ),"Atencao!")
	EndIf
Return


Static Function BuscaNatOp(cCFOP)
Local aArea     := GetArea()
Local aAreaUP0  := GetArea("UP0")
Local aCFOP     := {""}
Local cTipoOper := ""
Local lSeek     := .F.
Local nLen      := 0
Local nI        := 0
Local nTipo     := 0

cCFOP := If(ValType(cCFOP)=="U","000",Alltrim(cCFOP))

DbSelectArea("UP0")
UP0->(DbSetOrder(1))
UP0->(DbGoTop())
If DbSeek(xFilial("UP0")+cCFOP)
	If !Empty(UP0->UP0_TIPO)
		cTipoOper := UP0->UP0_TIPO
	EndIf
EndIf
//Se nใo encontrar o registro exato, busca o primeiro tipo cadastrado
If Empty(cTipoOper)
	nLen := Len(cCFOP)
	
	If nLen == 4
		aCFOP := {}
		
		If (Left(cCFOP,1) == "1") .Or. (Left(cCFOP,1) == "2") .Or. (Left(cCFOP,1) == "3")
			aAdd(aCFOP, "1" + Right(cCFOP, 3))
			aAdd(aCFOP, "2" + Right(cCFOP, 3))
			aAdd(aCFOP, "3" + Right(cCFOP, 3))
		ElseIf (Left(cCFOP,1) == "5") .Or. (Left(cCFOP,1) == "6") .Or. (Left(cCFOP,1) == "7")
			aAdd(aCFOP, "5" + Right(cCFOP, 3))
			aAdd(aCFOP, "6" + Right(cCFOP, 3))
			aAdd(aCFOP, "7" + Right(cCFOP, 3))
		Else
			aAdd(aCFOP, cCFOP )
		EndIf
	Else
		aCFOP := {}
		aAdd(aCFOP, cCFOP )
	EndIf
	
	DbSelectArea("UP0")
	UP0->(DbSetOrder(1))
	UP0->(DbGoTop())
	
	For nI := 1 to Len(aCFOP)
		lSeek := DbSeek(xFilial("UP0")+aCFOP[nI])
		If lSeek
			If !Empty(UP0->UP0_TIPO)
				cTipoOper := UP0->UP0_TIPO
				Exit
			Else
				lSeek := .F.
				Loop
			EndIf
		EndIf
	Next
EndIf

If Empty(cTipoOper)
	nTipo := 0
Else
	nTipo := If(UP0->UP0_TIPO=="N",1,If(UP0->UP0_TIPO=="B",2,If(UP0->UP0_TIPO=="D",3,If(UP0->UP0_TIPO=="C",4,If(UP0->UP0_TIPO=="R",5,6)))))
EndIf 
Return (nTipo)


Static Function BuscaXML(cCaminho)
	Local aFiles := {}
	Local nCount
	Local nX
	
	//Limpa marcacao de registros no Grid
	LimpaMarca()
	
	If !Empty(cCaminho)
		cCaminho := Iif(Right(Trim(cCaminho),1)=="\",Alltrim(cCaminho),Alltrim(cCaminho)+"\")
		
		aBrowse        := {}  //limpo lista apresentada
		oBrowse:AARRAY := {}  //limpo lista apresentada
		
		aFiles := Directory(cCaminho+"*.XML", "")  //Apresenta os dados dos arquivos
		nCount := Len( aFiles )
		
		For nX := 1 to nCount  
			aAdd(aBrowse,{.F.,cCaminho,aFiles[nX,1],"",.F.})
			aAdd(oBrowse:AARRAY,{.F.,cCaminho,aFiles[nX,1],"",.F.})
		Next nX

		If nCount = 0
			MsgAlert("Nใo foram encontrados arquivos no diret๓rio: " + cCaminho,cTitulo)
		EndIf
		
		oBrowse:ResetLen()
		oBrowse:DrawSelect()
	Else
		MsgAlert("Selecione o Diretorio para busca dos arquivos XML.",cTitulo)
	EndIf
Return


Static Function LimpaMarca()
	lChk := .F.
	oCheck:CtrlRefresh()
	aEval(aBrowse,{|x| x[1]:=lChk})
Return


Static Function DigCodSubs(cNota,cSerie,nSeq)
Local cConsulta := GetSx3Cache("D1_COD","X3_F3")

Chkproc := .F.

//Vou posicionar no 1o registro da SB1, para nao permitir registro vazio do cEdit1
DbSelectArea("SB1")
SB1->(DbGoTop())
dbSeek(xFilial("SB1"))

cEdit1 := Space(TamSX3("B1_COD")[1])

DEFINE MSDIALOG _oDlg TITLE "NF: " +cNota + " - Serie: " + cSerie FROM C(1),C(1) TO C(240),C(350) PIXEL
			
// Cria as Groups do Sistema
@ C(002),C(003) TO C(090),C(175) ;
	LABEL "Informe o Codigo do Produto Protheus " ;
	PIXEL OF _oDlg
// Cria Componentes Padroes do Sistema
@ C(012),C(015) Say "Produto: "+cProduto+" - NCM: "+cNCM ;
	Size C(150),C(008);
	COLOR CLR_HBLUE ;
	PIXEL OF _oDlg
@ C(020),C(015) Say "Descricao: "+oDet[nSeq]:_Prod:_xProd:TEXT ;
	Size C(150),C(020);
	COLOR CLR_HBLUE ;
	PIXEL OF _oDlg
@ C(040),C(015) MsGet oEdit1 ;
	Var cEdit1 ;
	F3 cConsulta ;
	Valid ValProd() ;
	Size C(080),C(009) ;
	COLOR CLR_HBLUE ;
	PICTURE "@!" ; 
	PIXEL OF _oDlg
@ C(055),C(015) Say "Produto: "+Alltrim(cEdit1)+" - NCM: "+_NCMdigit ;
	Size C(150),C(008) ;
	COLOR CLR_HBLUE ;
	PIXEL OF _oDlg
@ C(065),C(015) Say "Descricao: "+_DESCdigit ;
	Size C(150),C(020) ;
	COLOR CLR_HBLUE ;
	PIXEL OF _oDlg
@ C(100),C(030) Button "Processar" ;
	Size C(037),C(012) ;
	PIXEL OF _oDlg ;
	Action( Iif(MsgYesNo("Confirma dados?", cTitulo), Troca(), .F. ))
@ C(100),C(080) Button "Cancelar" ;
	Size C(037),C(012) ;
	PIXEL OF _oDlg ;
	Action( Iif(MsgYesNo("Confirma cancelamento?", cTitulo), _oDlg:End(), .F. ))
oEdit1:SetFocus()

ACTIVATE MSDIALOG _oDlg CENTERED
Return


Static Function GetIdEnt()
Local aArea  := GetArea()
Local cIdEnt := ""
Local cURL   := PadR(GetNewPar("MV_SPEDURL","http://"),250)
Local oWs

oWS            := WsSPEDAdm():New()
oWS:cUSERTOKEN := "TOTVS"

oWS:oWSEMPRESA:cCNPJ                 := IIF(SM0->M0_TPINSC==2 .Or. Empty(SM0->M0_TPINSC),SM0->M0_CGC,"")
oWS:oWSEMPRESA:cCPF                  := IIF(SM0->M0_TPINSC==3,SM0->M0_CGC,"")
oWS:oWSEMPRESA:cIE                   := SM0->M0_INSC
oWS:oWSEMPRESA:cIM                   := SM0->M0_INSCM
oWS:oWSEMPRESA:cNOME                 := SM0->M0_NOMECOM
oWS:oWSEMPRESA:cFANTASIA             := SM0->M0_NOME
oWS:oWSEMPRESA:cENDERECO             := FisGetEnd(SM0->M0_ENDENT)[1]
oWS:oWSEMPRESA:cNUM                  := FisGetEnd(SM0->M0_ENDENT)[3]
oWS:oWSEMPRESA:cCOMPL                := FisGetEnd(SM0->M0_ENDENT)[4]
oWS:oWSEMPRESA:cUF                   := SM0->M0_ESTENT
oWS:oWSEMPRESA:cCEP                  := SM0->M0_CEPENT
oWS:oWSEMPRESA:cCOD_MUN              := SM0->M0_CODMUN
oWS:oWSEMPRESA:cCOD_PAIS             := "1058"
oWS:oWSEMPRESA:cBAIRRO               := SM0->M0_BAIRENT
oWS:oWSEMPRESA:cMUN                  := SM0->M0_CIDENT
oWS:oWSEMPRESA:cCEP_CP               := Nil
oWS:oWSEMPRESA:cCP                   := Nil
oWS:oWSEMPRESA:cDDD                  := Str(FisGetTel(SM0->M0_TEL)[2],3)
oWS:oWSEMPRESA:cFONE                 := AllTrim(Str(FisGetTel(SM0->M0_TEL)[3],15))
oWS:oWSEMPRESA:cFAX                  := AllTrim(Str(FisGetTel(SM0->M0_FAX)[3],15))
oWS:oWSEMPRESA:cEMAIL                := UsrRetMail(RetCodUsr())
oWS:oWSEMPRESA:cNIRE                 := SM0->M0_NIRE
oWS:oWSEMPRESA:dDTRE                 := SM0->M0_DTRE
oWS:oWSEMPRESA:cNIT                  := IIF(SM0->M0_TPINSC==1,SM0->M0_CGC,"")
oWS:oWSEMPRESA:cINDSITESP            := ""
oWS:oWSEMPRESA:cID_MATRIZ            := ""
oWS:oWSOUTRASINSCRICOES:oWSInscricao := SPEDADM_ARRAYOFSPED_GENERICSTRUCT():New()
oWS:_URL                             := AllTrim(cURL)+"/SPEDADM.apw"

If oWs:ADMEMPRESAS()
	cIdEnt                           := oWs:cADMEMPRESASRESULT
EndIf

RestArea(aArea)
Return (cIdEnt)


Static Function NFeChave(cChaveNFe,cIdEnt)
Local cURL    := PadR(GetNewPar("MV_SPEDURL","http://"),250)
Local oWS
Local lErrado := .F.

oWs            := WsNFeSBra():New()
oWs:cUserToken := "TOTVS"
oWs:cID_ENT    := cIdEnt
ows:cCHVNFE    := cChaveNFe
oWs:_URL       := AllTrim(cURL)+"/NFeSBRA.apw"

If oWs:ConsultaChaveNFE()
	cErro := ""
	
	If !Empty(oWs:oWSCONSULTACHAVENFERESULT:cVERSAO)
		cErro += " Versใo Msg:" + oWs:oWSCONSULTACHAVENFERESULT:cVERSAO
	EndIf
	
	cErro += " Amb.:"+": "+IIf(oWs:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1,"Produ็ใo","Homologa็ใo") //"Produ็ใo"###"Homologa็ใo"
	cErro += " Cod.Ret.NFe"+": "+oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE
	cErro += " Msg.Ret.NFe"+": "+oWs:oWSCONSULTACHAVENFERESULT:cMSGRETNFE
	
	If !Empty(oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO)
		cErro += " Prot."+": "+oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO
	EndIf
	
	//QUANDO NAO ESTIVER OK NAO IMPORTA, CODIGO DIFERENTE DE 100
	If oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE # "100"
		lErrado := .T.
	EndIf
Else
	lErrado := .T.		
EndIf
Return (lErrado)


