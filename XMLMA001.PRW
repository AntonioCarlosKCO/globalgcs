#Include "Protheus.ch"
#Include "RwMake.ch"

//versao do programa
Static Versao := "V1.01"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³XMLMA001   ºAutor  ³ Marcos            º Data ³ 22/11/2016  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Cadastro de Diretorios de XML                              º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³                                                            º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/                                                                

User Function XMLMA001() 
Local cFiltro     := ""           
PRIVATE cAlias    := "UP1"                       
PRIVATE cCadastro := "Cadastro de Diretórios de Importação de XML - " + Versao
PRIVATE aRotina   := {}                          

// Configurando as opcoes que estarao disponiveis ao usuario
AADD(aRotina, { "Pesquisar" , "AxPesqui"     , 0, 1 })
AADD(aRotina, { "Visualizar", "AxVisual"     , 0, 2 })
AADD(aRotina, { "Incluir"   , "u_XMA001D(1)" , 0, 3 })
AADD(aRotina, { "Alterar"   , "u_XMA001D(2)" , 0, 4 })
AADD(aRotina, { "Excluir"   , "AxDeleta"     , 0, 5 })        

DbSelectArea(cAlias)
DbSetOrder(1)
cFiltro := "UP1_FILIAL='"+xFilial("UP1")+"'"
Set Filter To &cFiltro
        
CursorWait()
CursorArrow()

mBrowse(0,0,0,0,cAlias,,,,,2)   
Return
                                       
User Function XMA001D(tipo)
Local oCam
Local oCancela
Local oSCaminho
Local oSelec
Local oDescr   
Local oSDescr  
Private cCam   := Space(250)
Private cDescr := Space(50)
Static oDlg

If tipo = 2
	cDescr := AllTrim(UP1->UP1_DESCRI) + Space(50)
	cCam   := AllTrim(UP1->UP1_PATH)   + Space(250)
Endif

DEFINE MSDIALOG oDlg TITLE "Inclua dos dados do Diretorio" FROM 000, 000  TO 110, 500 COLORS 0, 16777215 PIXEL

    @ 008, 005 SAY oSDescr PROMPT "Descrição:" SIZE 028, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 007, 034 MSGET oDescr VAR cDescr SIZE 193, 010 OF oDlg PICTURE "@!" COLORS 0, 16777215 PIXEL
    @ 022, 009 SAY oSCaminho PROMPT "Caminho:" SIZE 023, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 021, 034 MSGET oCam VAR cCam SIZE 193, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 021, 230 BUTTON oSelec PROMPT "..." SIZE 013, 010 OF oDlg ACTION u_XMLMA1G(1,tipo) PIXEL
    @ 036, 077 BUTTON oGrava PROMPT "Gravar" SIZE 039, 012 OF oDlg ACTION u_XMLMA1G(2,tipo) PIXEL
    @ 036, 136 BUTTON oCancela PROMPT "Cancelar" SIZE 038, 012 OF oDlg ACTION oDlg:End() PIXEL

ACTIVATE MSDIALOG oDlg CENTERED
Return                                          


User Function XMLMA1G(acao,tipo)
Local aArea := GetArea()

	If acao = 1 
		cCam := cGetFile('','Escolha o Diretorio', 0, Iif( IsSrvUnix(), "/SPOOL/","\SPOOL\"), .T.,GETF_RETDIRECTORY+GETF_LOCALHARD+GETF_NETWORKDRIVE+GETF_LOCALFLOPPY,.F. )
	Else
		//ambos os objetos tem que estar preenchidos
		If !Empty(cDescr) .And. !Empty(cCam)
		
			//verifico se o diretorio existe
			If ExistDir(cCam)
			
				DbSelectArea("UP1")
				UP1->(DbSetOrder(1))

	    		If tipo = 1
    				RecLock("UP1",.T.)
	    			UP1->UP1_FILIAL := xFilial("UP1")
			   		UP1->UP1_CODIGO := GetSx8Num("UP1","UP1_CODIGO")
			   		ConfirmSx8()
		    	Else
    				UP1->(dbSeek(xFilial("UP1")+UP1->UP1_CODIGO))
    				RecLock("UP1",.F.)
		    	Endif 
    	
    			UP1->UP1_DESCRI := AllTrim(cDescr)
				UP1->UP1_PATH   := AllTrim(cCam)
	    		UP1->(MsUnlock())
				oDlg:End()
		    Else
		    	MsgAlert("Diretório inválido.","Cadastro de Diretórios")
	    	Endif
	   Else
	    	MsgAlert("Favor informar todos os campos.","Cadastro de Diretórios")
       Endif
	Endif
	
	RestArea(aArea)
Return                    