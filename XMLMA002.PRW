#Include "Protheus.ch"
#Include "RwMake.ch"

//versao do programa
Static Versao := "V1.01"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³XMLMA002   ºAutor  ³ Marcos            º Data ³ 22/11/2016  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Cadastro de CFOP                                           º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³                                                            º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/                                                                

User Function XMLMA002() 
Local cFiltro     := ""           
Local lSeek       := .F.
PRIVATE cAlias    := "UP0"                       
PRIVATE cCadastro := "Cadastro de Natureza - "+Versao
PRIVATE aRotina   := {}                          

// Configurando as opcoes que estarao disponiveis ao usuario
AADD(aRotina, { "Pesquisar" , "AxPesqui"     , 0, 1 })
AADD(aRotina, { "Visualizar", "AxVisual"     , 0, 2 })
AADD(aRotina, { "Alterar"   , "AxAltera"     , 0, 4 })

DbSelectArea(cAlias)
DbSetOrder(1)

//Busco se existe registros para filial corrente, se nao, populo tabela com dados do CFOP do SX5 - Tabela 13
lSeek	:= UP0->(DbSeek(xFilial("UP0")))
If !lSeek
	Begin Transaction
		Processa({|| Cadast_UP0() }, cCadastro, "Aguarde... Inserindo Registros...", .F.)
	End Transaction
EndIf
		
cFiltro := "UP0_FILIAL='"+xFilial("UP0")+"'"
Set Filter To &cFiltro
        
CursorWait()
CursorArrow()

UP0->(DbGoTop())
mBrowse(0,0,0,0,cAlias,,,,,2)   
Return
                                       
Static Function Cadast_UP0()
Local	aArea		:= GetArea()
Local	aAreaSX5	:= GetArea("SX5")
Local	cCodTabela	:= "13"
Local	nCont		:= 1000
	
DbSelectArea("SX5")
SX5->(DbSetOrder(1))
SX5->(DbGoTop())
lSeek := DbSeek(xFilial("SX5")+cCodTabela)

If lSeek
	ProcRegua(nCont)
	Do While !SX5->(Eof()) .And. SX5->X5_TABELA == cCodTabela .And. SX5->X5_FILIAL ==  xFilial("SX5")
		IncProc("Aguarde incluindo CFOP: "+Alltrim(SX5->X5_CHAVE))
	
		DbSelectArea("UP0")
		RecLock("UP0",.T.)
		UP0->UP0_FILIAL	:= xFilial("UP0")
		UP0->UP0_NATURE	:= SX5->X5_CHAVE
		UP0->UP0_TIPO	:= " "
		UP0->UP0_DESNAT := AllTrim(SX5->X5_DESCRI)
		UP0->(MsUnlock())
		
		SX5->(DbSkip())
	EndDo
	IncProc(" ")
Else
	MsgAlert("Falha ao incluir CFOP, verifique se existe a Tabela 13 para esta Filial",cTitulo)
EndIf

SX5->(dbCloseArea())
RestArea(aAreaSX5)
RestArea(aArea)
Return()

