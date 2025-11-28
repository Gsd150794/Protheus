/*
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
   Autor     |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 14/08/24 | Chamado 48138. Vanderlei. Correção ortografica da palarva Embarque na variavel cCadastro.
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço | 29/08/24 | Chamado 48362. Vanderlei. Reestruturação dos códigos do cadastro de locais de embarque.
=============================================================================================================================== 
*/
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS136
Autor-------------: Alex Wallauer
Data da Criacao---: 22/05/2023
===============================================================================================================================
Descrição---------: Rotina de manutenção do Cadastro de Local de Embarque . Chamado 43864.
===============================================================================================================================
Parametros--------: Nenhum 
===============================================================================================================================
Retorno-----------: Nenhum 
===============================================================================================================================
*/  
User Function AOMS136()
Private aTela[0][0],aGets[0]
Private cCadastro	:= "Cadastro de Local de Embarque"
Private aRotina	:= MenuDef()

mBrowse(,,,,"ZEL")

Return       

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alex Wallauer
Data da Criacao---: 22/05/2023
===============================================================================================================================
Descrição---------: Utilizacao de Menu Funcional
===============================================================================================================================
Parametros--------: aRotina
					1. Nome a aparecer no cabecalho
					2. Nome da Rotina associada
					3. Reservado
					4. Tipo de Transa‡„o a ser efetuada:
						1 - Pesquisa e Posiciona em um Banco de Dados
						2 - Simplesmente Mostra os Campos
						3 - Inclui registros no Bancos de Dados
						4 - Altera o registro corrente
						5 - Remove o registro corrente do Banco de Dados
					5. Nivel de acesso
					6. Habilita Menu Funcional
===============================================================================================================================
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina:={{ "Pesquisar" , "AxPesqui"      , 0 , 1 } ,;
                { "Visualizar", "AxVisual"      , 0 , 2 } ,;
                { "Incluir"   , "U_AOM136Inclui", 0 , 3 } ,;
                { "Alterar"   , "AxAltera"      , 0 , 4 } ,;
                { "Excluir"   , "AxDeleta"      , 0 , 5 }  }


Return( aRotina )
/*
===============================================================================================================================
Programa----------: U_AOM136Inclui
Autor-------------: Alex Wallauer
Data da Criacao---: 22/05/2023
===============================================================================================================================
Descricao---------: Manutenção do ZE0
===============================================================================================================================
Parametros--------: cAlias,nReg,nOpc
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================*/
User Function AOM136Inclui(cAlias,nReg,nOpc)

If nOpc = 3
   Return AxInclui(cAlias,nReg,nOpc,;
       /*aAcho>     */ ,;
       /*cFunc>     */ ,;
       /*aCpos>     */ ,;
       /*cTudoOk>   */ "U_AOMS136V('OK"+cAlias+"')",;
       /*lF3>       */ ,;
       /*cTransact> */ ,;//Antes 
       /*aButtons>  */ ,;
       /*aParam>    */ ,;
       /*aAuto>     */ ,;
       /*lVirtual>  */ ,;
       /*lMaximized>*/ )
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS136V
Autor-------------: Alex Wallauer
Data da Criacao---: 02/01/2023
===============================================================================================================================
Descrição---------: Validacao dos campos dos cadastros DO ZEL
===============================================================================================================================
Parametros--------: _cCampo := Nome do campo ou botao
===============================================================================================================================
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/  
User Function AOMS136V(_cCampo)

Local _lRet := .T.  // , F
DEFAULT _cCampo:=SubStr(ReadVar(),4)

DBSelectArea("ZEL")

   If _cCampo == "ZEL_CODIGO" 
      
      If Len(AllTrim(M->ZEL_CODIGO)) < 4 //.OR. (_lRet:=ExistChav("ZEL",M->ZEL_CODIGO,1))
         If Len(AllTrim(M->ZEL_CODIGO)) < 4
            U_ITMsg("Codigo do Local de Embarque INVALIDO.",'Atencao!',;
		   	        "Digite um codigo com 4 caracteres afanumericos.",1)         
            _lRet := .F.
         EndIf
      EndIf

   ElseIf _cCampo == "ZEL_DESCRI" 
      
      If Empty(M->ZEL_DESCRI) .Or. (_lRet:=ExistChav("ZEL",M->ZEL_DESCRI,2))
         If Empty(M->ZEL_DESCRI) 
            U_ITMsg("Descricao do Local de Embarque é obrigatorio.",'Atencao!',;
		   	        "Digite um codigo que não exista no cadastro.",1)         
            _lRet := .F.
         EndIf
      EndIf

   ElseIf _cCampo == "ZEL_FILFIS" 

      If !Empty(M->ZEL_FILFIS) 
         _lRet:=ExistCpo("SM0",cEmpAnt+M->ZEL_FILFIS,1)
      EndIf

   ElseIf _cCampo == "ZEL_LOCAL" 

      If !Empty(M->ZEL_LOCAL) 
         _lRet:=ExistCpo("NNR",M->ZEL_LOCAL)
      EndIf

   ElseIf _cCampo == "ZEL_OPERAD" 

      If !Empty(M->ZEL_OPERAD) 
         _lRet:=ExistCpo("SA2",M->ZEL_OPERAD)
      Else
         M->ZEL_LOJAOP:=Space(Len(ZEL->ZEL_LOJAOP))
         M->ZEL_NOMEOP:=Space(Len(SA2->A2_NREDUZ))
      EndIf

   ElseIf _cCampo == "ZEL_LOJAOP" 

      If !Empty(M->ZEL_OPERAD) 
         _lRet:=ExistCpo("SA2",M->ZEL_OPERAD+M->ZEL_LOJAOP)
      EndIf

   ElseIf _cCampo == "ZEL_CAPALE" 
         _lRet:=Positivo(M->ZEL_CAPALE)
   ElseIf _cCampo == "ZEL_CAPKG" 
         _lRet:=Positivo(M->ZEL_CAPKG)
   ElseIf _cCampo == "OKZEL"

         If !Obrigatorio(aGets,aTela)
            Return .F.
         EndIf
         If Inclui                   //ZEL_FILIAL+ZEL_FILFIS+ZEL_LOCAL+ZEL_OPERAD+ZEL_LOJAOP
            _lRet :=ExistChav("ZEL",M->ZEL_FILIAL+M->ZEL_FILFIS+M->ZEL_LOCAL+M->ZEL_OPERAD+M->ZEL_LOJAOP,3)
         EndIf

   EndIf
   
Return _lRet

/*
===============================================================================================================================
Programa----------: U_BuscaLocalEmbarque
Autor-------------: Alex Wallauer
Data da Criacao---: 22/05/2023
===============================================================================================================================
Descrição---------: Busca o Local do Embarque do Pedido no Cadastro de Local do Embarque .
===============================================================================================================================
Parametros--------: _cFilAtual - Código da Filial Fiscal (cFilAnt)
------------------: _cLocal    - Código do Armazem       (_cLocal1oItem)
------------------: _cVend1    - Código do Vendedor      (M->C5_VEND1)
===============================================================================================================================
Retorno-----------: Local de Embarque 
===============================================================================================================================
*/  
User Function BuscaLocalEmbarque(_cFilAtual,_cLocal,_cVend1)

Local _cFilial    := xFilial("ZEL")
Local _lAchou     := .F.
Local _cCodLocEmb := Space(Len(ZEL->ZEL_CODIGO))

DEFAULT _cFilAtual:= cFilAnt
DEFAULT _cLocal   := Space(Len(ZEL->ZEL_LOCAL))
DEFAULT _cVend1   := Space(Len(SC5->C5_VEND1))

ZEL->(DBSetOrder(3))//ZZEL_FILIAL+ZEL_FILFIS+ZEL_LOCAL+ZEL_OPERAD+ZEL_LOJAOP
If _cFilAtual = "20"
   If _cVend1 = "001622" .And. _cLocal $ "50/52"
	   _cRegraZEL := "2) Buscou por Filial Fiscal = 20, Armazem = "+_cLocal
	   _cCodLocEmb:= "RS50"
      _lAchou:=.T.
   EndIf
ElseIf _cFilAtual = "40"
   If _cLocal $ "50/52"
	   _cRegraZEL := "3) Buscou por Filial Fiscal = 40, Armazem = "+_cLocal
	   _cCodLocEmb:= "MG50"
      _lAchou:=.T.
   EndIf
ElseIf _cFilAtual $ "90/93"
   If ZEL->(DBSeek(_cFilial+_cFilAtual+_cLocal+Space(Len(ZEL->(ZEL_OPERAD+ZEL_LOJAOP)))))
   	_cRegraZEL := "4) Buscou por Filial Fiscal = "+_cFilAtual+", Armazem = "+_cLocal
   	_cCodLocEmb:= ZEL->ZEL_CODIGO 
      _lAchou:=.T.
   EndIf 
EndIf
If !_lAchou .And. ZEL->(DBSeek(_cFilial+_cFilAtual+Space(Len(ZEL->(ZEL_LOCAL+ZEL_OPERAD+ZEL_LOJAOP)))))
	_cRegraZEL := "1) Buscou por Filial Fiscal = "+_cFilAtual
	_cCodLocEmb:= ZEL->ZEL_CODIGO 
EndIf 
ZEL->(DBSetOrder(1))

Return _cCodLocEmb
