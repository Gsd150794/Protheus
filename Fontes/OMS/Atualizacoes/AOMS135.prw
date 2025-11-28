/*
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
   Autor      |    Data    |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 23/02/2023 | Chamado 43076. Ajustes no Cadastro de Assistente Adm Comercial responsável.
Alex Wallauer | 22/03/2023 | Chamado 42203.  Troca da funcao de AOM134Inclui para AOM135Inclui
=============================================================================================================================== 

=========================================================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado - Motivo da Alteração
---------------------------------------------------------------------------------------------------------------------------------------------------------
Jerry Santiago   -  Igor Melgaço     - 05/09/2024 - 27/09/2024 - 48088   - Ajustes para validações de registros na inclusão e alteração.
=========================================================================================================================================================
*/
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS135
Autor-------------: Alex Wallauer
Data da Criacao---: 13/01/2023
===============================================================================================================================
Descrição---------: Rotina de manutenção do Cadastro de Assistente Adm Comercial Responsável Chamado 42054.
===============================================================================================================================
Parametros--------: Nenhum 
===============================================================================================================================
Retorno-----------: Nenhum 
===============================================================================================================================
*/  
User Function AOMS135()
Local _cTitulo := "Cadastro de Assistente Adm Comercial Responsável"
Local _aDadosR:={}

ACY->( DBSetOrder(1) )
ACY->( DBGoTop() )
While ACY->(!Eof()) 
	aAdd( _aDadosR , ACY->ACY_GRPVEN+"-"+AllTrim( ACY->ACY_DESCRI ) )
   ACY->( DBSkip() )
EndDo

_cSelecZZL:="SELECT  ZZL_MATRIC , ZZL_NOME FROM "+RETSQLNAME("ZZL")+" ZZL WHERE D_E_L_E_T_ = ' ' AND ZZL_PEDPOR  = 'S' ORDER BY ZZL_MATRIC " 

_aItalac_F3:={}
//  (_aItalac_F3,{"1CPO_CAMPO1"  ,_cTabela  ,_nCpoChave                , _nCpoDesc              ,_bCondTab, _cTitAux     , _nTamChv           , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"M->ZPG_ASSCOD",_cSelecZZL,{|Tab| (Tab)->ZZL_MATRIC }, {|Tab| (Tab)->ZZL_NOME},         ,"Assistentes" ,Len(ZPG->ZPG_ASSCOD),          , 1        } )

//AD(_aItalac_F3,{"1CPO_CAMPO1   ,_cTabel,_nCpoChave, _nCpoDesc,_bCondTab, _cTitAux , _nTamChv           , _aDados , _nMaxSel, _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"M->ZPG_REDCOD",       ,          ,          ,         ,"Redes"   ,Len(ACY->ACY_GRPVEN),_aDadosR ,1        })

//AxCadastro("ZPG",_cTitulo, "U_DelOk()", "U_COK()"            , aRotAdic, bPre, bOK, bTTS, bNoTTS,aAuto,nOpcAuto,aButtons,aACS,cTela)
//AxCadastro("ZPG",_cTitulo,            , "U_AOMS135V('OKZPG')",         ,     ,    , )

Private cCadastro	:= _cTitulo
Private aRotina	:= MenuDef()
mBrowse(,,,,"ZPG")

Return       

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
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

Local aRotina:={{ "Pesquisar"	, "AxPesqui" 	  , 0 , 1 } ,;
				{ "Visualizar"	, "AxVisual" 	  , 0 , 2 } ,;
				{ "Incluir"		, "U_AOM135Inclui", 0 , 3 } ,;
				{ "Alterar"		, "U_AOM135Altera" 	  , 0 , 4 } ,;
				{ "Excluir"		, "AxDeleta"	  , 0 , 5 }  }


Return( aRotina )
/*
===============================================================================================================================
Programa----------: U_AOM135Inclui
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
===============================================================================================================================
Descricao---------: Manutenção do ZE0
===============================================================================================================================
Parametros--------: cAlias,nReg,nOpc
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================*/
User Function AOM135Inclui(cAlias,nReg,nOpc)

If nOpc = 3
   Return AxInclui(cAlias,nReg,nOpc,;
       /*aAcho>     */ ,;
       /*cFunc>     */ ,;
       /*aCpos>     */ ,;
       /*cTudoOk>   */ "U_AOMS135V()",;
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
Programa----------: BuscaAssistente
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
===============================================================================================================================
Descrição---------: Busca o/a Assistente do Pedido no Cadastro de Assistente Adm Comercial Responsável.
===============================================================================================================================
Parametros--------: _cRede - Código da Rede        (SA1->A1_GRPVEN)
------------------: _cVend - Código do Vendedor    (SC5->C5_VEND1)
------------------: _cSupe - Código do Supervisor  (SC5->C5_VEND4)
------------------: _cCoor - Código do Coordenador (SC5->C5_VEND2)
------------------: _cGere - Código do Gerente     (SC5->C5_VEND3)
===============================================================================================================================
Retorno-----------: Nenhum 
===============================================================================================================================
*/  
User Function BuscaAssistente(_cRede,_cVend,_cSupe,_cCoor,_cGere)
Local _aOrdBusca  :={} , A
Local _aAssistente:={"",""}
Local _cRedB:=Space(Len(ZPG->ZPG_REDCOD))
Local _cVenB:=Space(Len(ZPG->ZPG_VENCOD))
Local _cSupB:=Space(Len(ZPG->ZPG_SUPCOD))
Local _cCooB:=Space(Len(ZPG->ZPG_COOCOD))
Local _cGerB:=Space(Len(ZPG->ZPG_GERCOD))
//Busca com REDE
aAdd(_aOrdBusca,_cRede+_cVend+_cSupe+_cCoor+_cGere)// ORDEM 01
aAdd(_aOrdBusca,_cRede+_cVenB+_cSupe+_cCoor+_cGere)// ORDEM 02
aAdd(_aOrdBusca,_cRede+_cVenB+_cSupB+_cCoor+_cGere)// ORDEM 03
aAdd(_aOrdBusca,_cRede+_cVenB+_cSupB+_cCooB+_cGere)// ORDEM 04
aAdd(_aOrdBusca,_cRede+_cVenB+_cSupB+_cCooB+_cGerB)// ORDEM 05
//Busca sem REDE
aAdd(_aOrdBusca,_cRedB+_cVend+_cSupe+_cCoor+_cGere)// ORDEM 06
aAdd(_aOrdBusca,_cRedB+_cVenB+_cSupe+_cCoor+_cGere)// ORDEM 07
aAdd(_aOrdBusca,_cRedB+_cVenB+_cSupB+_cCoor+_cGere)// ORDEM 08
aAdd(_aOrdBusca,_cRedB+_cVenB+_cSupB+_cCooB+_cGere)// ORDEM 09 

ZPG->(DBSetOrder(8))//ZPG_FILIAL+ZPG_REDCOD+ZPG_VENCOD+ZPG_SUPCOD+ZPG_COOCOD+ZPG_GERCOD+ZPG_ASSCOD
For A := 1 TO Len(_aOrdBusca)
   If ZPG->(DBSeek( xFilial()+_aOrdBusca[A]+"2" )) 
       _aAssistente[1] := ZPG->ZPG_ASSCOD
       _aAssistente[2] := ZPG->ZPG_ASSNOM//Posicione('ZZL',1,xFilial('ZZL')+ZPG->ZPG_ASSCOD,'ZZL_NOME') 
       Exit
   EndIf
Next
ZPG->(DBSetOrder(1))

Return _aAssistente


/*
===============================================================================================================================
Programa----------: U_AOM135Inclui
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
===============================================================================================================================
Descricao---------: Manutenção do ZE0
===============================================================================================================================
Parametros--------: cAlias,nReg,nOpc
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================*/
User Function AOM135Altera(cAlias,nReg,nOpc)

If nOpc = 4

          //AxAltera(cAlias,nReg,nOpc,/*aAcho*/,/*aCpos*/,/*nColMens*/,/*cMensagem*/,/*cTudoOk*/,/*cTransact*/,/*cFunc*/,/*aButtons*/,/*aParam*/,/*aAuto*/,/*lVirtual*/,/*lMaximized*/)
   Return AxAltera(cAlias,nReg,nOpc,         ,         ,            ,             ,"U_AOMS135V()",,)

EndIf

Return .T.


/*
===============================================================================================================================
Programa----------: AOM135V
Autor-------------: Igor Melgaço
Data da Criacao---: 27/09/2024
===============================================================================================================================
Descricao---------: Validação no OK final da rotina
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================*/
User Function AOMS135V()
Local aAreaZPG := {}
Local nRecnoZPG := 0
Local _lRet := .T.

Begin Sequence

   If (Inclui .Or. Altera)
   
      If Empty(M->ZPG_REDCOD+M->ZPG_VENCOD+M->ZPG_SUPCOD+M->ZPG_COOCOD+M->ZPG_GERCOD)
         U_ITMsg("Não é possivel gravar somente o Assistente.",'Atencao!',;
		           'Preencha pelo menos mais um campo chave para o pedido poder encontrar o Assistente.',1)         
         _lRet := .F.
      EndIf

      If _lRet

         aAreaZPG := Getarea("ZPG")
         nRecnoZPG := IIf(Inclui,0,ZPG->(Recno()))
         
         //Verifico se há registro na chave 
         DBSelectArea("ZPG")
         DBSetOrder(7)
         If DBSeek(xFilial("ZPG")+M->ZPG_REDCOD+M->ZPG_VENCOD+M->ZPG_SUPCOD+M->ZPG_COOCOD+M->ZPG_GERCOD+M->ZPG_ASSCOD) 
            If Inclui .Or. ZPG->(Recno()) <> nRecnoZPG
               If Inclui 
                  _lRet := .F.
               ElseIf Altera
                  If ZPG->(Recno()) <> nRecnoZPG
                     _lRet := .F.
                  EndIf  
               EndIf
               If !_lRet
                  U_ITMsg("Não é possivel concluir a operação pois há outro registro ativo para chave digitada (Rede + Vendedor + Supervisor + Coordenador + Gerente + Assistente)!",'Atencao!',;
                     'Preencha uma chave diferente para concluir a operação.',1)     
               EndIf
            EndIf
         EndIf

         If _lRet .And. M->ZPG_MSBLQL == "2"
            //Verifico se há registro ativo para estrutura sem o Assistente pois só pode haver um
            DBSelectArea("ZPG")
            DBSetOrder(8)
            If DBSeek(xFilial("ZPG")+M->ZPG_REDCOD+M->ZPG_VENCOD+M->ZPG_SUPCOD+M->ZPG_COOCOD+M->ZPG_GERCOD+"2") 
               If Inclui 
                  _lRet := .F.
               ElseIf Altera
                  If ZPG->(Recno()) <> nRecnoZPG
                     _lRet := .F.
                  EndIf  
               EndIf

               If !_lRet
                  U_ITMsg("Não é possivel concluir a operação pois há outro registro ativo para chave digitada (Rede + Vendedor + Supervisor + Coordenador + Gerente)!",'Atencao!',;
                     'Bloqueie o registro ativo dessa chave anteriormente e inclua ou preencha uma chave diferente para concluir a operação.',1)         
               EndIf

            EndIf
         EndIf
         FWRestArea(aAreaZPG)
      EndIf

   EndIf
   
End Sequence

Return _lRet
