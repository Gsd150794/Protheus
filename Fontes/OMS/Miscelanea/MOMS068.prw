/*  
====================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS -                             
====================================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
------------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  | 08/09/2022 | Chamado 41021. Ajuste para declaração de variáveis corrigindo error.log.
Igor Melgaço  | 14/11/2022 | Chamado 41021. Cricao do tipo de acordo de Provisao.
Igor Melgaço  | 18/11/2022 | Chamado 41885. Ajuste para correção de error.log.
Igor Melgaço  | 21/11/2022 | Chamado 41900. Ajuste para correção de error.log.
Alex Wallauer | 28/11/2022 | Chamado 41909. Solictacao de Ajustes diversos.
Alex Wallauer | 16/12/2022 | Chamado 41909. Ajuste para correção de error.log.
Alex Wallauer | 23/01/2023 | Chamado 42627. Ajuste na gravacao da alteraco da provisao.
Alex Wallauer | 23/03/2023 | Chamado 43367. Ajuste no calculo que usa o campo D1_VALDESC para diminuir e não somar.
Alex Wallauer | 05/06/2023 | Chamado 44045. Correcao de erro.log: argument #0 error, expected C->D, function left (L:2208).
Igor Melgaço  | 17/11/2023 | Chamado 45466. Inicio de compensação após a geração do título no financeiro e atraves do botão outras ações.
Igor Melgaço  | 09/01/2024 | Chamado 45466. Ajustes para novo status de contrato compensado.
Igor Melgaço  | 07/03/2024 | Chamado 45466. Novos ajustes para inclusão de contratos.
Igor Melgaço  | 04/04/2024 | Chamado 45466. Ajuste para envio do e-mail após efetivação.
Igor Melgaço  | 03/06/2024 | Chamado 47398. Ajuste para nova regra de envio do e-mail após efetivação.
Igor Melgaço  | 04/06/2024 | Chamado 47424. Ajuste no F3 do Favorecido.
Igor Melgaço  | 05/06/2024 | Chamado 47424. Ajuste envio do email qdo deleta parcela do contrato na efetivação.
Igor Melgaço  | 31/07/2024 | Chamado 47890. Ajuste envio do email e opção de reenvio.
Igor Melgaço  | 16/09/2024 | Chamado 48541. Ajuste no envio do email.
Igor Melgaço  | 19/09/2024 | Chamado 48576. Ajuste no ZK1_SUBITE para 2 caracteres.
Lucas Borges  | 23/07/2025 | Chamado 51340. Ajustar função para validação de ambiente de teste
=============================================================================================================================== 
Analista        - Programador     - Inicio     - Envio      - Chamado - Motivo de Alteração
===============================================================================================================================
Antonio Ramos   - Igor Melgaço    - 19/12/2024 - 19/12/2024 - 49414   - Ajuste para novo tipo de contrato.
Antonio Ramos   - Igor Melgaço    - 03/01/2025 - 19/02/2025 - 49014   - Ajuste na gravação de titulos
Vanderlei Alves - Igor Melgaço    - 18/02/2025 - 19/02/2025 - 49014   - Ajuste para inclusão de modelo Mix de Contrato.
Antonio Ramos   - Igor Melgaço    - 17/04/2025 - 17/04/2025 - 50244   - Ajuste para inclusão de menudef
Antonio Ramos   - Igor Melgaço    - 11/04/2025 - 24/04/2025 - 50254   - Ajuste para verificação se o vendedor/sup/gerente percentem ao cliente
Antonio Ramos   - Igor Melgaço    - 11/04/2025 - 24/04/2025 - 50244   - Ajuste para inclusão qdo subitem For 07 - Comite 
Alexandro       - Igor Melgaço    - 25/04/2025 - 25/04/2025 - 50525   - Ajuste para remoção de diretório local.
Antonio Neves   - Antonio Neves   - 06/05/2025 - 06/05/2025 - 50605   - Ajustar a função SUBS da valiadção do SUBITE 07
Andre           - Igor Melgaço    - 29/05/2025 - 28/11/2025 - 50805   - Ajuste para calculo do valor de rateio e retirada das opções do campo ZK1_SUBITE para chamar consulta padrão.
Antonio Ramos   - Julio Paz       - 21/11/2025 - 28/11/2025 - 52565   - Ajustes na gravação do histórico da rotina de acordos comerciais.
====================================================================================================================================================================================== 
*/
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "topconn.ch"
#Include "msmgadd.ch"
#Include "dbtree.ch"
#Include "RWMake.ch"

#DEFINE _ENTER CHR(13)+CHR(10)

//Picture DOS CAMPOS NUMERICOS
Static _cPictQTDE  := "@E 999,999,999,999.9999" //Getsx3cache("C6_UNSVEN" ,"X3_PICTURE")
Static _cPictVLNET := "@E 999,999,999,999.999"
Static _cPictVALOR := "@E 999,999,999,999.99"  //Getsx3cache("C6_VALOR"  ,"X3_PICTURE")

/*
===============================================================================================================================
Programa--------: MOMS068 // U_MOMS068
Autor-----------: Alex Wallauer
Data da Criacao-: 12/08/2022
===============================================================================================================================
Descrição-------: CHAMADO 41021. Controle de Acordos Comerciais
===============================================================================================================================
Parametros------: NENHUM
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MOMS068()// U_MOMS068
Private aRotina    := MenuDef()
Private cCadastro  := "Controle de Acordos Comerciais"
Private __cNumCont := ""
Private __aContrat := {}

aCores := {{"ZK1_STATUS = '1'", 'BR_AMARELO'	},;
			 {"ZK1_STATUS = '2'", 'BR_VERDE'	   },;
			 {"ZK1_STATUS = '3'", 'BR_VERMELHO' },;
          {"ZK1_STATUS = '4'", 'BR_AZUL'     },;
			 {"ZK1_STATUS = '5'", 'BR_BRANCO'   },;
          {"ZK1_STATUS = '6'", 'BR_PRETO'    }}

mBrowse(,,,,"ZK1",,,,,,aCores)

Return


/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Fricks
Data da Criacao---: 17/04/2025
===============================================================================================================================
Descrição---------: Função utilizada para criação do menu
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: aRotina - Opções de menu
===============================================================================================================================
*/
Static Function MenuDef()
Local aRotina2 := {{ "Pesquisar"           ,"AxPesqui"		    , 1 , 1 },; 
            { "Visualizar"          ,'U_MOMS68Manut(02)', 2 , 2 },; 
            { "Incluir"             ,'U_MOMS68Manut(03)', 3 , 3 },; 
            { "Alterar"             ,'U_MOMS68Manut(04)', 4 , 4 },; 
            { "Excluir"             ,'U_MOMS68Manut(05)', 5 , 5 },; 
            { "Efetivar"            ,'U_MOMS68Manut(06)', 2 , 4 },; 
            { "Cancela Efetivacao"  ,'U_MOMS68Manut(07)', 2 , 2 },; 
            { "Recusar"             ,'U_MOMS68Manut(08)', 2 , 2 },; 
            { "Cancela Recusa"      ,'U_MOMS68Manut(09)', 2 , 2 },; 
            { "Encaminha Acordos"   ,'U_MOMS68Manut(10)', 2 , 2 },; 
            { "Compensação"         ,'U_MOMS68NT(2)'    , 2 , 2 },; 
            { "Reprocessamento de Status"         ,'FWMsgRun( ,{|oproc| U_MOMS68AT(oproc) },"Reprocessando Status.","Aguarde...")'     , 2 , 2 },; 
            { "Legenda"             ,'U_MOMS68Legenda()', 2 , 2 }}  
           
Return( aRotina2 )



/*
===============================================================================================================================
Programa--------: MOMS68Manut
Autor-----------: Alex Wallauer
Data da Criacao-: 12/08/2022
===============================================================================================================================
Descrição-------: Controle de Acordos Comerciais. CHAMADO 41021
===============================================================================================================================
Parametros------: NENHUM
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MOMS68Manut(_nOpc As Numeric)
Local _aParAux  := {} As Array, nI As Numeric
Local _aParRet  := {} As Array
Local _aDados   := {} As Array
Local _cCombo   := "" As Char

If _nOpc = 6 //EFETIVACAO

   If ZK1->ZK1_STATUS <>  "4"
      U_ITMsg("Esse acordo não pode ser Efetivado!","Atenção","O Acordo deve ser encaminhado para poder ser efetivado",3)
      Return .F.
   EndIf

   ZK3->(DBSetOrder(1))
   If ZK3->(DBSeek(xFilial("ZK3")+ZK1->ZK1_CODIGO ))
      If !Empty(ZK3->ZK3_TITULO) 
         U_ITMsg("EFETIVACAO JÁ GERADA","Atenção","Cancele a efetivacao atual para usar essa opcao.",3)
         Return .F.
      EndIf
   Else
      U_ITMsg("ACORDO SEM LANCAMENTO DE PARCELAS","Atenção",,3)
      Return .F.
   EndIf

ElseIf _nOpc = 7 //CANCELA EFETIVACAO

   ZK3->(DBSetOrder(1))
   If ZK3->(DBSeek(xFilial("ZK3")+ZK1->ZK1_CODIGO ))
      If Empty(ZK3->ZK3_TITULO) 
         U_ITMsg("EFETIVACAO NÃO GERADA","Atenção","O acordo deve esta efetivado para usar essa opcao.",3)
         Return .F.
      EndIf
   Else
      U_ITMsg("ACORDO SEM LANCAMENTO DE PARCELAS","Atenção",,3)
      Return .F.
   EndIf

   _lRetorno:=.T.
   If U_ITMsg("Confirma o Cancelamento da Efetivacao ?",'Atenção!',,3,2,3,,"CONFIRMA","SAIR")
      FWMsgRun(,{|oproc|  _lRetorno := MExcluiNCC(oproc)   },"Aguarde...","Excluindo NCC...")
      If _lRetorno
         U_ITMsg("CANCELAMENTO DA EFTIVACAO FEITA COM SUCESSO","Atenção",,2)
      EndIf
   EndIf
   Return .T.

ElseIf _nOpc = 8 //RECUSAR

   ZK3->(DBSetOrder(1))
   If ZK3->(DBSeek(xFilial("ZK3")+ZK1->ZK1_CODIGO ))
      If !Empty(ZK3->ZK3_TITULO) 
         U_ITMsg("EFETIVACAO JÁ GERADA","Atenção","Cancele a efetivacao atual para usar essa opcao.",3)
         Return .F.
      EndIf
   EndIf

   If U_ITMsg("Confirma Recusar ?",'Atenção!',,3,2,3,,"CONFIRMA","SAIR")
      ZK1->(RecLock("ZK1", .F.))            
      ZK1->ZK1_EFETDT:=Date()
      ZK1->ZK1_EFEUSE:=AllTrim(UsrFullName(__cUserId))
      ZK1->ZK1_STATUS:="3"      
      ZK1->(MSUnLock())
      U_ITMsg("RECUSA FEITA COM SUCESSO","Atenção",,2)
   EndIf
   Return .T.

ElseIf _nOpc = 9 //CANCELA RECUSA

    If ZK1->ZK1_STATUS <> "3"
         U_ITMsg("ESSE ACORDO NAO ESTA RECUSADO.","Atenção",,3)
         Return .F.
    EndIf

   If U_ITMsg("Confirma o Cancelamento da Recusa ?",'Atenção!',,3,2,3,,"CONFIRMA","SAIR")
      ZK1->(RecLock("ZK1", .F.))            
      ZK1->ZK1_EFETDT:=CTOD("")
      ZK1->ZK1_EFEUSE:=""
      ZK1->ZK1_STATUS:="1"
      ZK1->(MSUnLock())
      U_ITMsg("CANCELAMENTO DA RECUSA FEITO COM SUCESSO","Atenção",,2)
   EndIf
   Return .T.

ElseIf _nOpc = 4 .Or. _nOpc = 5 //ALTERACAO OU EXCLUSAO

   ZK3->(DBSetOrder(1))
   If ZK3->(DBSeek(xFilial("ZK3")+ZK1->ZK1_CODIGO ))
      If !Empty(ZK3->ZK3_TITULO) 
         U_ITMsg("EFETIVACAO JÁ GERADA","Atenção","Cancele a efetivacao atual para usar essa opcao.",3)
         Return .F.
      EndIf
   EndIf

ElseIf _nOpc = 10 //ENCAMINHA ACORDOS

   aItens:={}
   FWMsgRun(,{|oproc|  aItens:=U_MOM68Query(.T.)  }, "LENDO DADOS...","LENDO DADOS...")
   
   If Len(aItens) > 0 
      aCabE:={}
      aAdd(aCabE,""            )//01
      aAdd(aCabE,"Acordo"      )//02
      aAdd(aCabE,"Gerente"     )//03
      aAdd(aCabE,"Rede"        )//04
      aAdd(aCabE,"Cliente"     )//05
      aAdd(aCabE,"Valor Acordo")//06
      aAdd(aCabE,"Observacao"  )//07
      aAdd(aCabE,"Registro"    )//08
   
      _cTitulo:='SELECAO DE ACORDOS ENCAMINHADOS'
      While .T.
                          //      ,_aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
         If U_ITListBox(_cTitulo,aCabE,aItens, .T. , 2    ,        ,          ,        ,         ,     ,        , )
             _lTemMarcado:=.F.
             For nI := 1 TO Len(aItens)           
                 If aItens[nI,1]// *********** LE MARCADOS  ***************
                    ZK1->(DBGoTo( aItens[nI][Len(aItens[nI])] ))
   	              ZK1->(RecLock("ZK1",.F.))
   	              ZK1->ZK1_STATUS := "4"//4-Encaminhado
   	              ZK1->ZK1_ENCADT := Date()
   	              ZK1->ZK1_ENCUSE := AllTrim(UsrFullName(__cUserId))
                    ZK1->(MSUnLock())            
                    _lTemMarcado:=.T.
                 EndIf
             Next
             If _lTemMarcado
     	          U_ITMsg("ACORDOS GRAVADOS COM SUCESSO",'GRAVACAO OK',,2)
             Else
     	          U_ITMsg("Selecione 1 ou mais Acordos para atualiza-los para Encamihado",'Atenção!',,3)
                Loop
             EndIf
      
         EndIf
         Exit
      EndDo
   EndIf
   Return .T.
EndIf

//// *********************  VISUALIZAR (2) / INCLUSAO (3) / ALTERACAO (4) / EXCLUSAO (5) / EFETIVACAO (6) *******************************

_cSelectSB1:="SELECT B1_COD , B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE D_E_L_E_T_ = ' ' AND B1_TIPO = 'PA' AND B1_MSBLQL <> '1' ORDER BY B1_COD "
_bSA1Select:={||"SELECT A1_COD , A1_LOJA , A1_NOME , A1_NREDUZ , A1_CGC "+;
                " FROM "+RetSqlName("SA1")+" SA1 "+;
                " LEFT JOIN "+RetSqlName("SA3")+" SA3   ON SA1.A1_VEND    = SA3.A3_COD   AND SA3.D_E_L_E_T_   = ' ' "+;
                " WHERE A1_MSBLQL <> '1' "+;
                " AND SA1.D_E_L_E_T_ = ' ' "+;
                If(!Empty(MV_PAR04)," AND A1_GRPVEN = '"+MV_PAR04+"'",If(!Empty(MV_PAR05)," AND SA1.A1_COD = '"+MV_PAR05+"' ",""))+;      
                " GROUP BY A1_COD , A1_LOJA , A1_NOME , A1_NREDUZ , A1_CGC "+;
                " ORDER BY A1_COD, A1_LOJA "  }

_bSC5Select:={|| U_MOM68Query(.F.) }

_cCombo := Getsx3cache("B1_I_BIMIX","X3_CBOX")//"G1=Grupo 1;G2=Grupo 2;G3=Grupo 3;G9=Outros;G0=Indefinido"
_cCombo := StrTran(_cCombo,"=","-")
_aDados := StrTokArr(_cCombo, ';')

_aItalac_F3:={}//       1             2           3                                     4                        5                  6                    7         8          9         10         11        12
//  (_aItalac_F3,{"CPOCAMPO"     ,_cTabela   ,_nCpoChave                           , _nCpoDesc               ,_bCondTab        ,_cTitAux           , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR10"     ,_cSelectSB1,{|Tab|(Tab)->B1_COD}                 ,{|Tab|(Tab)->B1_DESC}                       ,,"Produtos Tipo = PA",          ,          ,          ,.F.        ,       , } )
aAdd(_aItalac_F3,{"M->ZK1_FAVORE",_bSA1Select,{|Tab|(Tab)->A1_COD+(Tab)->A1_LOJA}  ,{|Tab|(Tab)->A1_CGC+" "+AllTrim((Tab)->A1_NOME)+" / "+(Tab)->A1_NREDUZ}            ,,"Favorecidos"   ,          ,          ,1         ,.F.        ,       , } )
aAdd(_aItalac_F3,{"M->ZK3_FAVORE",_bSA1Select,{|Tab|(Tab)->A1_COD+(Tab)->A1_LOJA}  ,{|Tab|(Tab)->A1_CGC+" "+AllTrim((Tab)->A1_NOME)+" / "+(Tab)->A1_NREDUZ}            ,,"Favorecidos"   ,          ,          ,1         ,.F.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR12"     ,_bSC5Select,{|Tab|(Tab)->C5_NUM},{|Tab| DToC(SToD((Tab)->C5_EMISSAO))+" / "+(Tab)->C5_CLIENTE+" "+(Tab)->C5_LOJACLI+" / "+(Tab)->C5_I_NOME},,"Pedidos"       ,          ,          ,          ,.F.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR15"     ,           ,                                     ,                         ,                ,"Grupo Mix",2       ,_aDados  ,Len(_aDados)} )

//_cCombo := Getsx3cache("ZK1_TIPOAC","X3_CBOX")
_cCombo := "7-Investimento;8-Acordo Comercial;9-Pendencia"
_cCombo := StrTran(_cCombo,"=","-")
_aTiposAcor:= StrTokArr(_cCombo, ';')//"1-Aniversario","2-Reforma Reinauguracao","3-Acao Comercial","4-Rebaixa de preco","5-Introducao de produto"

_cCombo := Getsx3cache("ZK1_SUBITE","X3_CBOX")
_cCombo := StrTran(_cCombo,"=","-")
_aSubAcor:= StrTokArr(_cCombo, ';')//"1-Aniversario","2-Reforma Reinauguracao","3-Acao Comercial","4-Rebaixa de preco","5-Introducao de produto"

MV_PAR01:=Date()
MV_PAR02:=Date()
MV_PAR03:=Space(100)
MV_PAR04:=Space(Len(SC5->C5_I_GRPVE))
MV_PAR05:=Space(Len(SA2->A2_COD))
MV_PAR06:=Space(Len(SA2->A2_LOJA))
MV_PAR07:=Space(Len(SC5->C5_VEND1))
MV_PAR08:=Space(Len(SC5->C5_VEND1))
MV_PAR09:=Space(Len(SC5->C5_VEND1))
MV_PAR10:=Space(200)
MV_PAR11:="1" //Forma de Apuracao: 1=Sobre Faturamento
MV_PAR12:=Space(200)
MV_PAR13:="2"
MV_PAR14:="1"
MV_PAR15:=Space(100)
MV_PAR16:="8-Acordo Comercial"
MV_PAR17:="01"
MV_PAR18:=Space(100)
MV_PAR19:="2"
MV_PAR20:="2"

_cTitulo:=cCadastro

If _nOpc = 3 //INCLUSAO  ******************************************

   cVal:='Vazio().OR.ExistCpo("SA1",MV_PAR05+AllTrim(MV_PAR06))'
 
   aAdd( _aParAux , { 1 , "Emissão de"          , MV_PAR01, "@D", "" , ""	    , "" , 050                , .T.  })
   aAdd( _aParAux , { 1 , "Emissão ate"         , MV_PAR02, "@D", "" , ""	    , "" , 050                , .T.  })
   aAdd( _aParAux , { 1 , "Filial"              , MV_PAR03, "@!", "" ,"LSTFIL" , "" , 100                , .F.  }) 
   aAdd( _aParAux , { 1 , "Redes"	            , MV_PAR04, "@!", "" , "ACY2"  , "Empty(MV_PAR05) .And. Empty(MV_PAR06)" , 100, .F. } )
   aAdd( _aParAux , { 1 , "Cliente"             , MV_PAR05, "@!", "" , "SA1"   , "Empty(MV_PAR04)"       , Len(SA1->A1_COD)   , .F. } )
   aAdd( _aParAux , { 1 , "Loja  "	            , MV_PAR06, "@!",cVal,""	    , "Empty(MV_PAR04)"       , Len(SA1->A1_LOJA)  , .F. } )
   aAdd( _aParAux , { 1 , "Gerente"             , MV_PAR07, "@!", "" , "SA3_02", "" , Len(SC5->C5_VEND1) , .F. } )
   aAdd( _aParAux , { 1 , "Coordenador"         , MV_PAR08, "@!", "" , "SA3_01", "" , Len(SC5->C5_VEND1) , .F. } )
   aAdd( _aParAux , { 1 , "Vendedor"            , MV_PAR09, "@!", "" , "SA3BLQ", "" , Len(SC5->C5_VEND1) , .F. } )
   aAdd( _aParAux , { 1 , "Produtos"            , MV_PAR10, "@!", "" , "F3ITLC", "" , 100                , .F. } ) 
   aAdd( _aParAux , { 2 , "Filtrar por"         , MV_PAR11, {"1-Data da NF    ","2-Data do Pedido"}   , 060 ,".T.",.T.,".T."}) 
   aAdd( _aParAux , { 1 , "Pedidos"             , MV_PAR12, "@!","", "F3ITLC", "" , 100 , .F. } ) 
   aAdd( _aParAux , { 2 , "Somar Impostos"      , 2       , {"1-Sim","2-Nao"}     , 060 ,".T.",.T.,".T."}) 
   aAdd( _aParAux , { 2 , "Considerar Devolucao", MV_PAR14, {"1-Sim","2-Nao"}     , 060 ,".T.",.T.,".T."}) 
   aAdd( _aParAux , { 1 , "Grupo Mix"           , MV_PAR15, "@!","" ,"F3ITLC", "" , 100 , .F. } ) 
   aAdd( _aParAux , { 2 , "Tipo do Acordo"      , MV_PAR16, _aTiposAcor           , 100 ,".T.",.T.,".T."})
   aAdd( _aParAux , { 1 , "Subtipo do Acordo"   , "01"    , "@!", "" , "X5_ZL"   , ""       , Len(ZK1->ZK1_SUBITE)   , .F. } )
   aAdd( _aParAux , { 1 , "UF"                  , MV_PAR18, "@!","" ,"LSTEST", "" , 100 , .F. } ) 
   aAdd( _aParAux , { 2 , "Inclui Provisão"     , 2       , {"1-Sim","2-Nao"}     , 060 ,".T.",.T.,".T."}) 
   aAdd( _aParAux , { 2 , "Inclui Mix"          , 2       , {"1-Sim","2-Nao"}     , 060 ,".T.",.T.,".T."}) 
      
   For nI := 1 To Len( _aParAux )
       aAdd( _aParRet , _aParAux[nI][03] )
   Next 
   
   While .T.
  
      _cTitulo:=cCadastro
     
      If !ParamBox( _aParAux , "Selecione os filtros" , _aParRet , {|| .T. } , , , , , , , .T. , .T. )
         Exit
      EndIf
      
      If !(MV_PAR02 >= MV_PAR01)
  	      U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3)
  	      Loop
  	   EndIf
  
      If (Empty(MV_PAR04+MV_PAR05+MV_PAR06)) .Or. (!Empty(MV_PAR04) .And.  !Empty(MV_PAR05+MV_PAR06))
  	      U_ITMsg("Preencha uma Rede ou um Cliente",'Atenção!',"Um dos 2 deve ser preenchido mas não os 2 juntos.",3)
  	      Loop
  	   EndIf
  
      If (Empty(MV_PAR07+MV_PAR08+MV_PAR09))
  	      U_ITMsg("Preencha pelo menos o Gerente ou o Coordelnador ou o Vendedor",'Atenção!',"Um dos 3 deve ser preenchido.",3)
  	      Loop
  	   EndIf
  
  	   _cTitulo+=" - "+DToC(DATE())+" - "+Time()
      If ValType(MV_PAR13) = "N"
         MV_PAR13:=Str(MV_PAR13,1)
      EndIf
      If ValType(MV_PAR16) = "N"
         MV_PAR16:=Str(MV_PAR16,1)
      EndIf
      If ValType(MV_PAR17) = "N"
         MV_PAR17:=StrZero(MV_PAR17,2)
      EndIf
      If ValType(MV_PAR19) = "N"
         MV_PAR19:=Str(MV_PAR19,1)
      EndIf
      If ValType(MV_PAR20) = "N"
         MV_PAR20:=Str(MV_PAR20,1)
      EndIf
  	   lSair := .F.
      
      lContinua := MOMS068VI()

      If lContinua
         _cCombo := Getsx3cache("ZK1_TIPOAC","X3_CBOX")
         //_cCombo := "6-Contrato;7-Investimento"
         _cCombo := StrTran(_cCombo,"=","-")
         _aTiposAcor:= StrTokArr(_cCombo, ';')//"1-Aniversario","2-Reforma Reinauguracao","3-Acao Comercial","4-Rebaixa de preco","5-Introducao de produto"

     	   FWMsgRun(,{|oproc|  lSair := MOMS68CP(oproc,_nOpc)  }, "Selecionando os Pedidos...","Filtrando pedidos..." )
     	   
     	   If !lSair
     	      Loop
     	   EndIf
        
         Exit
      Else
         Loop
      EndIf
  EndDo

Else//// VISUALIZAR (2) / ALTERACAO (4) / EXCLUIR (5)  / EFETIVACAO (6) *******************************

   _cCombo := Getsx3cache("ZK1_TIPOAC","X3_CBOX")
   //_cCombo := "6-Contrato;7-Investimento"
   _cCombo := StrTran(_cCombo,"=","-")
   _aTiposAcor:= StrTokArr(_cCombo, ';')//"1-Aniversario","2-Reforma Reinauguracao","3-Acao Comercial","4-Rebaixa de preco","5-Introducao de produto"

   FWMsgRun(,{|oproc|  lSair := MOMS68CP(oproc,_nOpc)  }, "LENDO DADOS...","LENDO DADOS...")
	
EndIf	

Return .T.

/*
===============================================================================================================================
Programa--------: MOMS68CP
Autor-----------: Alex Wallauer
Data da Criacao-: 12/08/2022
===============================================================================================================================
Descrição-------: Pego os pedidos necessários para realizar a manutenção do acordo
===============================================================================================================================
Parametros------: oProc - objeto para o carregamento do FWMsgRun. / _nOpc - tipo do aRotina
===============================================================================================================================
Retorno---------: _lGrava
===============================================================================================================================*/
Static Function MOMS68CP(oproc As Object, _nOpc As Numeric) As Logical
Local _cQuery     := "" As Char, _nni As Numeric, nPos As Numeric, P As Numeric, Z2 As Numeric
Local _cAlias2    := GetNextAlias() As Char
Local _aPreCont   := {} As Array
Local _aPreCont2  := {} As Array
Local _cCombo     := "" As Char
Local _aTiposAcor := {} As Array
Local cDesc       := "" As Char
Local _nI         := 0 As Numeric
Local _cAliasSB1  := "" As Char
Local _cQuerySB1  := "" As Char
Local _aMIX       := {} As Array
Local _lMix       := .F. As Logical
Local _nAlt        := 0 As Numeric

Private _aProdMarca := {} As Array
Private _aProd2Marca := {} As Array
Private _lGrava     := .F. As Logical
Private aCols       := {} As Array

_cCombo     := Getsx3cache("ZK1_TIPOAC","X3_CBOX")
_cCombo     := StrTran(_cCombo,"=","-")
_aTiposAcor := StrTokArr(_cCombo, ';')//"1-Aniversario","2-Reforma Reinauguracao","3-Acao Comercial","4-Rebaixa de preco","5-Introducao de produto"

//************** COLUNAS DO BROWSE DE MARCA E DESMARCA APOS TELA DE FILTRO ANTES DA TELA PRINCIPAL  ******************************
   aCab:={}
   aCposPOZK2:={}
   aAdd(aCab,"")//01 - MARCACAO
   aAdd(aCab,"")//02 - LEGENDA
   aAdd(aCab,"Tipo Acordo / Cod.")//03 - Tipo do Acordo

   aAdd(aCab,"Filial")//04
   _nPosFil:=Len(aCab)
   aAdd(aCposPOZK2,{"ZK2_PEDFIL",_nPosFil,.F.})
    
   aAdd(aCab,"Pedido")//05
   _nPosPed:=Len(aCab)
   aAdd(aCposPOZK2,{"ZK2_PEDIDO",_nPosPed,.F.})

   //Forma de Apuracao: 1=Sobre Faturamento
    If (_nOpc = 3  .And. MV_PAR11 = "1") .Or. (_nOpc <> 3  .And. ZK1->ZK1_FORAPU = "1") .Or. Subs(MV_PAR19,1,1) = "1" 
      aAdd(aCab,"Nota Fiscal")//NOTA 06 
      _nPosNF:=Len(aCab)//06

      aAdd(aCab,Getsx3cache("C5_EMISSAO","X3_TITULO")) //07

    Else //FORMA DE APURACAO: 2=SOBRE PEDIDO
    
      aAdd(aCab,Getsx3cache("C5_EMISSAO","X3_TITULO")) //06

      aAdd(aCab,"Nota Fiscal")//NOTA 07
      _nPosNF:=Len(aCab)//07
    EndIf

    aAdd(aCab,"Cod. Produto")//08
    _nPosPRD:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_PRODUT",_nPosPRD,.F.})
    
    aAdd(aCab,"Descricao do Produto")//09
    _nPosDES:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_DESCRI",_nPosDES,.F.})

    aAdd(aCab,"Grupo Mix") //10
    _nPosBMix:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_BMIX",_nPosBMix,.F.})


    aAdd(aCab,Getsx3cache("C5_I_OPER" ,"X3_TITULO"))
    aAdd(aCab,Getsx3cache("C5_CLIENTE","X3_TITULO"))
    _nPoscLI:=Len(aCab)
    aAdd(aCab,Getsx3cache("C5_LOJACLI","X3_TITULO"))
    _nPosLoj:=Len(aCab)
    aAdd(aCab,Getsx3cache("C5_I_NOME" ,"X3_TITULO"))
    _nPosNomeCli:=Len(aCab)
    aAdd(aCab,Getsx3cache("C5_I_EST"  ,"X3_TITULO"))
    aAdd(aCab,Getsx3cache("C5_VEND1"  ,"X3_TITULO"))
    aAdd(aCab,Getsx3cache("C5_VEND2"  ,"X3_TITULO"))
    aAdd(aCab,Getsx3cache("C5_VEND3"  ,"X3_TITULO"))
    aAdd(aCab,Getsx3cache("C5_I_GRPVE","X3_TITULO"))
    
    aAdd(aCab,"Qtde. Pedido (2a)")//QTDE DO PEDIDO NA 2 UM - Qtde. Pedido (2a) - C6_UNSVEN - ZK2_QPED2U
    _nPosUNSVEN:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_QPED2U",_nPosUNSVEN,.T.})
    
    aAdd(aCab,"UM (2a)")//UM (2a) - C6_SEGUM   - ZK2_UNIDAD
    _nPosSEGUM:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_UNIDAD",_nPosSEGUM,.F.})
    
    aAdd(aCab,"Vlr. Pedido")//Valor pedidos- C6_VALOR   - ZK2_VRPEDI - RATEIO
    _nPosVLRIT:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_VRPEDI",_nPosVLRIT,.T.})

    aAdd(aCab,"Qtde. Faturada")//QTDE DO FATURAMENTO - Qtde Faturada 2UM - D2_QTSEGUM - ZK2_QFAT2U
    _nPosQTDEFA:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_QFAT2U",_nPosQTDEFA,.T.})
    
    aAdd(aCab,Getsx3cache("D2_SEGUM" ,"X3_TITULO"))
    
    aAdd(aCab,"Vr fat s/imp")//Vr fat s/ imp - D2_TOTAL   - ZK2_VRFATM)
    _nPosVLRFA:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_VRFATM",_nPosVLRFA,.T.})
    
    //Campos NOVOS
    aAdd(aCab,Getsx3cache("ZK2_QPED1U","X3_TITULO"))//Qtde Ped 1UM - C6_QTDVEN - ZK2_QPED1U
    _nPosQPED1U:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_QPED1U",_nPosQPED1U,.T.})

    aAdd(aCab,Getsx3cache("ZK2_PECTPE","X3_TITULO"))// ZK2_PECTPE - (Percentual de desconto contratual)
    //_nPosPECTPE:=Len(aCab)
    //aAdd(aCposPOZK2,{"ZK2_PECTPE",_nPosPECTPE,.T.})

    aAdd(aCab,Getsx3cache("ZK2_VRCTPE","X3_TITULO"))//Vlr desc cont ped - C6_I_VLRDC - ZK2_VRCTPE
    _nPosVRCTPE:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_VRCTPE",_nPosVRCTPE,.T.})

    aAdd(aCab,Getsx3cache("ZK2_QFAT1U","X3_TITULO"))//Qtde Faturada 1UM - D2_QUANT   - ZK2_QFAT1U
    _nPosQFAT1U:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_QFAT1U",_nPosQFAT1U,.T.})

    aAdd(aCab,Getsx3cache("ZK2_VRFATI","X3_TITULO"))//Vr fat c/ imp   - D2_VALBRUT - ZK2_VRFATI
    _nPosVRFATI:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_VRFATI",_nPosVRFATI,.T.})

    aAdd(aCab,Getsx3cache("ZK2_VRCTFA","X3_TITULO"))//Vr contrato fat - D2_I_VLRDC - ZK2_VRCTFA
    _nPosVRCTFA:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_VRCTFA",_nPosVRCTFA,.T.})

    aAdd(aCab,Getsx3cache("ZK2_QDEV1U","X3_TITULO"))//Qtde Dev 1UM    - D1_QUANT   - ZK2_QDEV1U
    _nPosQDEV1U:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_QDEV1U",_nPosQDEV1U,.T.})

    aAdd(aCab,Getsx3cache("ZK2_QDEV2U","X3_TITULO"))//Qtde Dev 2UM    - D1_QTSEGUM - ZK2_QDEV2U
    _nPosQDEV2U:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_QDEV2U",_nPosQDEV2U,.T.})

    aAdd(aCab,Getsx3cache("ZK2_VRDEVM","X3_TITULO"))//Vr Dev s/ imp   - D1_TOTAL   - ZK2_VRDEVM
    _nPosVLRDE:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_VRDEVM",_nPosVLRDE,.T.})

    aAdd(aCab,Getsx3cache("ZK2_VRDEVI","X3_TITULO"))//Vr Dev c/ imp   - DEVCOMIMP  - ZK2_VRDEVI
    _nPosVRDEVI:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_VRDEVI",_nPosVRDEVI,.T.})

    aAdd(aCab,Getsx3cache("ZK2_VRCTDE","X3_TITULO"))//Vr contrato dev - D1_I_VLRDC - ZK2_VRCTDE
    _nPosVRCTDE:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_VRCTDE",_nPosVRCTDE,.T.})
    //Campos NOVOS Comissoes
    aAdd(aCab,Getsx3cache("ZK2_COMIS1","X3_TITULO"))//ZK2_COMIS1 - C6_COMIS1 - % de Comissao do Vendedor
    _nPos1Comis:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_COMIS1",_nPos1Comis,.T.})

    aAdd(aCab,Getsx3cache("ZK2_COMIS2","X3_TITULO"))//ZK2_COMIS2 - C6_COMIS2 - % de Comissao do Coordenador
    _nPos2Comis:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_COMIS2",_nPos2Comis,.T.})
    
    aAdd(aCab,Getsx3cache("ZK2_COMIS3","X3_TITULO"))//ZK2_COMIS3 - C6_COMIS3 - % de Comissao do Gerente
    _nPos3Comis:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_COMIS3",_nPos3Comis,.T.})
    
    aAdd(aCab,Getsx3cache("ZK2_COMIS4","X3_TITULO"))//ZK2_COMIS4 - C6_COMIS4 - % de Comissao do Supervisor
    _nPos4Comis:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_COMIS4",_nPos4Comis,.T.})
    
    aAdd(aCab,Getsx3cache("ZK2_COMIS5","X3_TITULO"))//ZK2_COMIS5 - C6_COMIS5 - % de Comissao do Gerente Nacional
    _nPos5Comis:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_COMIS5",_nPos5Comis,.T.})
    
    //Campos NOVOS Calculos:
    aAdd(aCab,"Valor Apurado")    //ZK2_VRAPUR - VALOR PEDIDOS (VR FAT S/IMP - VR DEV S/IMP) - (VR FAT C/IMP - VR DEV C/ IMP)
    _nPosVrApur:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_VRAPUR",_nPosVrApur,.T.})
    
    aAdd(aCab,"Vr Net Pedido")    //ZK2_NETPED - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
    _nPosNETPE:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_NETPED" ,_nPosNETPE,.T.})
    
    aAdd(aCab,"Vr Net Ajustado")  //ZK2_NETAJU - (VR FAT S/ IMP - VR DEV S/ IMP)   /(QTDE FAT 1UM - QTDE DEV 1 UM)
    _nPosNETAJ:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_NETAJU" ,_nPosNETAJ,.T.})
    
    aAdd(aCab,"Qtde Apurada 1UM") //ZK2_QAPU1U - C6_QTDVEN - D2_QUANT  - (D2_QUANT  - D1_QUANT)
    _nPosQAPU1:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_QAPU1U" ,_nPosQAPU1,.T.})
    
    aAdd(aCab,"Qtde Apurada 2UM") //ZK2_QAPU2U - C6_UNSVEN - D2_QTSEGUM - (D2_QTSEGUM - D1_QTSEGUM)
    _nPosQAPU2:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_QAPU2U" ,_nPosQAPU2,.T.})
    
    aAdd(aCab,"Rateio")//RATEIO DO ACORDO POR ITEM DE PEDIDO
    _nPosVLRat:=Len(aCab)
    aAdd(aCposPOZK2,{"ZK2_RATEIO" ,_nPosVLRat,.T.})

    aAdd(aCab,"Reg")//11

//************** COLUNAS DO BROWSE DE MARCA E DESMARCA APOS TELA DE FILTRO ANTES DA TELA PRINCIPAL  ******************************

//************** COLUNAS DO BROWSE DO MEIO DA TELA / PRODUTOS ACUMULADO  //////////////////////////////////////////////////////
aCab2:={};aCposZK2:={}
aAdd(aCab2,"Produto")          //01- ZK2_PRODUT 
n2PosProd:=Len(aCab2)
//              "CAMPO"    ,nPosicao ,lNumerico = .T.
aAdd(aCposZK2,{"ZK2_PRODUT",n2PosProd,.F.            })

aAdd(aCab2,"Descricao")        //02- ZK2_DESCRI
n2PosDesc:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_DESCRI",n2PosDesc,.F.})

aAdd(aCab2,"Grupo Mix")
n2PosBMix:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_BMIX",n2PosBMix,.F.})

aAdd(aCab2,"Valor Apurado")    //03- ZK2_VRAPUR - VALOR PEDIDOS (VR FAT S/IMP - VR DEV S/IMP) - (VR FAT C/IMP - VR DEV C/ IMP)
n2PosVrApur:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_VRFATM",n2PosVrApur,.T.})

//aAdd(aCposZK2,{"ZK2_VRAPUR",n2PosVrApur,.T.})


aAdd(aCab2,"Valor Rateio")     //04- ZK2_RATEIO
n2PosVrRa:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_RATEIO" ,n2PosVrRa,.T.})

aAdd(aCab2,"% Rateio")         //05- ZK2_RATPER
n2PosPeRa:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_RATPER" ,n2PosPeRa,.T.})

aAdd(aCab2,"Vr Net Pedido")    //06 - ZK2_NETPED - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
n2PosNETPE:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_NETPED" ,n2PosNETPE,.T.})

aAdd(aCab2,"Vr Net Ajustado")  //07 - ZK2_NETAJU - (VR FAT S/ IMP - VR DEV S/ IMP)   /(QTDE FAT 1UM - QTDE DEV 1 UM)
n2PosNETAJ:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_NETAJU" ,n2PosNETAJ,.T.})

aAdd(aCab2,"Qtde Apurada 1UM") //08 - ZK2_QAPU1U - C6_QTDVEN - D2_QUANT  - (D2_QUANT  - D1_QUANT)
n2PosQAPU1:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_QAPU1U" ,n2PosQAPU1,.T.})

aAdd(aCab2,"Qtde Apurada 2UM") //09 - ZK2_QAPU2U - C6_UNSVEN - D2_QTSEGUM - (D2_QTSEGUM - D1_QTSEGUM)
n2PosQAPU2:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_QAPU2U" ,n2PosQAPU2,.T.})

aAdd(aCab2,"Qtde Ped 1UM")     //10 - C6_QTDVEN - ZK2_QPED1U
n2PosQ1Ped:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_QPED1U",n2PosQ1Ped,.T.})

aAdd(aCab2,"Qtde Ped 2UM")     //11 - C6_UNSVEN - ZK2_QPED2U
n2PosQPed:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_QPED2U",n2PosQPed,.T.})

aAdd(aCab2,"UM (2a)")          //12 - C6_SEGUM - ZK2_UNIDAD
n2PosUn2u:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_UNIDAD",n2PosUn2u,.F.})

aAdd(aCab2,"Valor pedidos")    //13 - C6_VALOR - ZK2_VRPEDI
n2PosVPed:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_VRPEDI",n2PosVPed,.T.})

aAdd(aCab2,"Vr Contr Pedido")  //14 - C6_I_VLRDC - ZK2_VRCTPE - (Valor do desconto contratual do pedido) (Calculo na SELECT (Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC) )
n2PosCPed:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_VRCTPE",n2PosCPed,.T.})

aAdd(aCab2,"Qtde Faturada 1UM")//15 - D2_QUANT - ZK2_QFAT1U
n2PosQ1Fat:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_QFAT1U",n2PosQ1Fat,.T.})

aAdd(aCab2,"Qtde Faturada 2UM")//16 - D2_QTSEGUM - ZK2_QFAT2U
n2PosQ2Fat:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_QFAT2U",n2PosQ2Fat,.T.})

aAdd(aCab2,"Vr fat s/ imp")    //17 - Vr fat s/ imp   - D2_TOTAL   - ZK2_VRFATM - RATEIO
n2PosVRFAM:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_VRFATM",n2PosVRFAM,.T.})

aAdd(aCab2,"Vr fat c/ imp")    //18 - Vr fat c/ imp   - D2_VALBRUT - ZK2_VRFATI
n2PosVRFAI:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_VRFATI",n2PosVRFAI,.T.})

aAdd(aCab2,"Vr contrato fat")  //19 - Vr contrato fat - D2_I_VLRDC - ZK2_VRCTFA
n2PosVRCTFA:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_VRCTFA",n2PosVRCTFA,.T.})

aAdd(aCab2,"Qtde Dev 1UM")     //20 - Qtde Dev 1UM    - D1_QUANT   - ZK2_QDEV1U
n2PosQDEV1U:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_QDEV1U",n2PosQDEV1U,.T.})

aAdd(aCab2,"Qtde Dev 2UM")     //21 - Qtde Dev 2UM    - D1_QTSEGUM - ZK2_QDEV2U
n2PosQDEV2U:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_QDEV2U",n2PosQDEV2U,.T.})

aAdd(aCab2,"Vr Dev s/ imp")    //22 - Vr Dev s/ imp   - D1_TOTAL   - ZK2_VRDEVM
n2PosVRDEM:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_VRDEVM",n2PosVRDEM,.T.})

aAdd(aCab2,"Vr Dev c/ imp")    //23 - Vr Dev c/ imp   - DEVCOMIMP  - ZK2_VRDEVI
n2PosVRDEI:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_VRDEVI",n2PosVRDEI,.T.})

aAdd(aCab2,"Vr.Cont.Dev")   //24 - Vr contrato dev - D1_I_VLRDC - ZK2_VRCTDE
n2PosVRCTDE:=Len(aCab2)
aAdd(aCposZK2,{"ZK2_VRCTDE",n2PosVRCTDE,.T.})
//**************  COLUNAS DO BROWSE DO MEIO DA TELA / PRODUTOS ACUMULADO //////////////////////////////////////////////////////

_cPictTOTAL:=_cPictVALOR//Getsx3cache("D2_TOTAL"  ,"X3_PICTURE")
_cPictQTSEG:=_cPictQTDE
_cPictVALDE:=Getsx3cache("D2_VALDEV" ,"X3_PICTURE")
_cPictPER  :=Getsx3cache("ZK2_COMIS1","X3_PICTURE")
//Picture DOS CAMPOS NUMERICOS

//****************************************** INCLUSAO  ******************************************

If _nOpc = 3 //INCLUSAO  ******************************************
   
   If ValType(MV_PAR19) = "N"
      MV_PAR19 := AllTrim(Str(MV_PAR19))
   EndIf
   If ValType(MV_PAR20) = "N"
      MV_PAR20 := AllTrim(Str(MV_PAR20))
   EndIf
   If Subs(MV_PAR20,1,1) = "1"

      _cAliasSB1 := GetNextAlias()
      _cQuerySB1 := " SELECT DISTINCT B1_I_BIMIX"
      _cQuerySB1 += " FROM "+RetSqlName("SB1")+" SB1 "
      _cQuerySB1 += " WHERE  SB1.D_E_L_E_T_ = ' ' "
      _cQuerySB1 += " AND SB1.B1_I_BIMIX <> ' ' "
      _cQuerySB1 += " ORDER BY B1_I_BIMIX "

      MPSysOpenQuery( _cQuerySB1 , _cAliasSB1)

      DBSelectArea(_cAliasSB1)
      (_cAliasSB1)->(DBGoTop())
      While (_cAliasSB1)->(!Eof())
         aAdd(_aMIX,(_cAliasSB1)->B1_I_BIMIX)
         
         (_cAliasSB1)->(DBSkip())
      EndDo

      (_cAliasSB1)->(DBCloseArea())
      
      For _nI := 1 To Len(_aMIX)

         _aProd := {}//VALORES CARACTERES PARA MOSTRAR CORRETO
         _aProd2:= {}//VALORES NUMERICOS PARA SOMAR


         aAdd(_aProd ,.T.) //01
         aAdd(_aProd2,.T.) //01
         aAdd(_aProd ,.T.) //02
         aAdd(_aProd2,.T.) //02

         aAdd(_aProd ,MV_PAR16)//03
         aAdd(_aProd2,MV_PAR16)//03 

         aAdd(_aProd ,xFilial("SC5"))
         aAdd(_aProd2,_aProd[Len(_aProd)]) //04
         
         aAdd(_aProd ,Space(Len(SC5->C5_NUM)))
         aAdd(_aProd2,_aProd[Len(_aProd)]) //05
         
         If (_nOpc = 3  .And. MV_PAR11 = "1") .Or. (_nOpc <> 3  .And. ZK1->ZK1_FORAPU = "1") .Or. Subs(MV_PAR19,1,1) = "1" 
            aAdd(_aProd ,Space(Len(SD2->(D2_DOC+"-"+D2_SERIE))))//_nPosNF
            aAdd(_aProd2,_aProd[Len(_aProd)])  //06

            aAdd(_aProd ,SToD(""))//D2_EMISSAO
            aAdd(_aProd2,_aProd[Len(_aProd)]) //07
         Else
            aAdd(_aProd ,SToD(""))//D2_EMISSAO
            aAdd(_aProd2,_aProd[Len(_aProd)]) //06

            aAdd(_aProd ,Space(Len(SD2->(D2_DOC+"-"+D2_SERIE))))//_nPosNF
            aAdd(_aProd2,_aProd[Len(_aProd)])  //07
         EndIf

         aAdd(_aProd ,"GRUPO "+_aMIX[_nI])//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //08
         
         If Subs(MV_PAR19,1,1) = "1"
            aAdd(_aProd , "PROVISAO")//
         Else
            aAdd(_aProd , "GRUPO MIX")//
         EndIf
         aAdd(_aProd2,_aProd[Len(_aProd)]) //09

         aAdd(_aProd ,_aMIX[_nI])
         aAdd(_aProd2,_aProd[Len(_aProd)]) //10

         aAdd(_aProd ,Space(Len(SC5->C5_I_OPER)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //11

         aAdd(_aProd ,Space(Len(SC5->C5_CLIENTE)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //12
         
         aAdd(_aProd ,Space(Len(SC5->C5_LOJACLI)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //13
         
         aAdd(_aProd ,Space(Len(SC5->C5_I_NOME)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //14
         
         aAdd(_aProd ,Space(Len(SC5->C5_I_EST)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //15
         
         aAdd(_aProd ,"")// ->C5_VEND1+"-"+Posicione("SA3",1,xFilial("SA3")+(_cAlias2)->C5_VEND1,"A3_NOME")
         aAdd(_aProd2,_aProd[Len(_aProd)]) //16
         
         aAdd(_aProd ,"")// (_cAlias2)->C5_VEND2+"-"+Posicione("SA3",1,xFilial("SA3")+(_cAlias2)->C5_VEND2,"A3_NOME")
         aAdd(_aProd2,_aProd[Len(_aProd)]) //17
         
         aAdd(_aProd ,"")//(_cAlias2)->C5_VEND3+"-"+Posicione("SA3",1,xFilial("SA3")+(_cAlias2)->C5_VEND3,"A3_NOME")
         aAdd(_aProd2,_aProd[Len(_aProd)]) //18
         
         aAdd(_aProd ,Space(Len(SC5->C5_I_GRPVE)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //19

         aAdd(_aProd ,TRANS(1,_cPictQTDE))//_cAlias2)->C6_UNSVEN
         aAdd(_aProd2,1) //20
         
         aAdd(_aProd ,"KG")//(_cAlias2)->C6_SEGUM
         aAdd(_aProd2,_aProd[Len(_aProd)]) //21
         
         aAdd(_aProd ,TRANS(1,_cPictVALOR))//Valor pedido - (_cAlias2)->C6_VALORI
         aAdd(_aProd2,0) //22
         
         aAdd(_aProd ,TRANS(1,_cPictQTSEG))//(_cAlias2)->D2_QTSEGUM
         aAdd(_aProd2,1) //23
         
         aAdd(_aProd ,"KG") //(_cAlias2)->D2_SEGUM
         aAdd(_aProd2,"KG")//24
         
         // C6_QTDVEN   (QUANTIDADE DO PEDIDO 1 UM)
         // C6_I_PDESC  (PERCENTUAL DE DESCONTO CONTRATUAL)
         // C6_I_VLRDC  (VALOR DO DESCONTO CONTRATUAL DO PEDIDO) (Calculo)
         // D2_QUANT    (QUANTIDADE FATURADA 1 UM)
         // D2_VALBRUT  (VLRCOMIMP VALOR FATURADO COM IMPOSTOS)
         // D2_I_VLRDC  (VLRCONTRATO, VALOR DO DESCONTO CONTRATUAL FATURADO)
         // D1_QUANT    (D1_QUANT) (QTDE DEVOLUÇÃO 1UM)
         // D1_QTSEGUM  (D1_QTSEGUM) (QTDE DEVOLUÇÃO 2UM)
         // DEVCOMIMP   (D1_TOTAL - D1_VALDESC + D1_ICMSRET) (VR DEVOLUÇÃO COM IMPOSTOS)
         // DEVCONTRATO (D1_I_VLRDC) (VALOR DO CONTRATO DEVOLUÇÃO)

         aAdd(_aProd ,TRANS(1,_cPictTOTAL))  // (_cAlias2)->D2_TOTAL ZK2_VRFATM - (Vr fat s/ impostos) (USADO NO RATEIO)
         aAdd(_aProd2,0)                       // ZK2_VRFATM - (Vr fat s/ impostos) (USADO NO RATEIO) 

         aAdd(_aProd ,TRANS(1,_cPictQTDE)    )// (_cAlias2)->C6_QTDVEN ZK2_QPED1U - (Quantidade do pedido 1 UM)
         aAdd(_aProd2,0                      )// ZK2_QPED1U - (Quantidade do pedido 1 UM)

         aAdd(_aProd ,TRANS(0,_cPictPER)    )// (_cAlias2)->C6_I_PDESC ZK2_PECTPE - (Percentual de desconto contratual)
         aAdd(_aProd2,0                     )//(_cAlias2)->C6_I_PDESC ZK2_PECTPE - (Percentual de desconto contratual)

         aAdd(_aProd ,TRANS(0,_cPictVALOR)  )//(_cAlias2)->C6_I_VLRDC ZK2_VRCTPE - (Valor do desconto contratual do pedido) (Calculo na SELECT (Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC) )
         aAdd(_aProd2,0                    )// ZK2_VRCTPE - (Valor do desconto contratual do pedido) (Calculo na SELECT (Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC) )
         
         aAdd(_aProd ,TRANS(1    ,_cPictQTDE) )//(_cAlias2)->D2_QUANT ZK2_QFAT1U - (Quantidade faturada 1 UM)
         aAdd(_aProd2,0                       )// ZK2_QFAT1U - (Quantidade faturada 1 UM)
         
         aAdd(_aProd ,TRANS(0  ,_cPictVALOR) )//(_cAlias2)->VLRCOMIMP ZK2_VRFATI - (VLRCOMIMP valor faturado com impostos)
         aAdd(_aProd2,0                     )// ZK2_VRFATI - (VLRCOMIMP valor faturado com impostos)
         
         aAdd(_aProd ,TRANS(1 ,_cPictVALOR))// (_cAlias2)->VLRCONTRATO ZK2_VRCTFA - (VLRCONTRATO, Valor do desconto contratual faturado)
         aAdd(_aProd2,0                    )// ZK2_VRCTFA - (VLRCONTRATO, Valor do desconto contratual faturado)

         //CAMPOS DE SUB SELECT DO SD1      
         _nD1_QUANT    := 1 //(_cAlias2)->D1_QUANT 
         _nD1_QTSEGUM  := 1 //(_cAlias2)->D1_QTSEGUM
         _nD2_VALDEV   := 0 //(_cAlias2)->D2_VALDEV
         _nDEVCOMIMP   := 0 //(_cAlias2)->DEVCOMIMP
         _nDEVCONTRATO := 0 //(_cAlias2)->DEVCONTRATO

         aAdd(_aProd ,TRANS(_nD1_QUANT    ,_cPictQTDE))// ZK2_QDEV1U  - SD1 - (Qtde devolução 1UM)
         aAdd(_aProd2,_nD1_QUANT                      )// ZK2_QDEV1U  - SD1 - (Qtde devolução 1UM)
         
         aAdd(_aProd ,TRANS(_nD1_QTSEGUM  ,_cPictQTDE))// ZK2_QDEV2U  - SD1 - (Qtde devolução 2UM)
         aAdd(_aProd2,_nD1_QTSEGUM                    )// ZK2_QDEV2U  - SD1 - (Qtde devolução 2UM)
         
         aAdd(_aProd ,TRANS(_nD2_VALDEV,_cPictVALDE)  )// ZK2_VRDEVM  - SD1 - Vr devolução SEM impostos) (D1_TOTAL)
         aAdd(_aProd2,_nD2_VALDEV                     )// ZK2_VRDEVM  - SD1 - (Vr devolução SEM impostos) (D1_TOTAL)

         aAdd(_aProd ,TRANS(_nDEVCOMIMP  ,_cPictVALOR))// ZK2_VRDEVI - SD1 - (Vr devolução com impostos) (D1_TOTAL - D1_VALDESC + D1_ICMSRET)
         aAdd(_aProd2,_nDEVCOMIMP                     )// ZK2_VRDEVI - SD1 - (Vr devolução com impostos) (D1_TOTAL - D1_VALDESC + D1_ICMSRET)
         
         aAdd(_aProd ,TRANS(_nDEVCONTRATO ,_cPictVALOR))// ZK2_VRCTDE - SD1 - (Valor do contrato devolução)
         aAdd(_aProd2,_nDEVCONTRATO                   )// ZK2_VRCTDE - SD1 - (Valor do contrato devolução)

         //CAMPOS DE SUB SELECT DO SD1      
         aAdd(_aProd ,TRANS(0,_cPictPER)     )//(_cAlias2)->C6_COMIS1 ZK2_COMIS1 - C6_COMIS1 - % de Comissao do Vendedor
         aAdd(_aProd2,0                      )// ZK2_COMIS1 - C6_COMIS1 - % de Comissao do Vendedor
         aAdd(_aProd ,TRANS(0,_cPictPER)     )// (_cAlias2)->C6_COMIS2 ZK2_COMIS2 - C6_COMIS2 - % de Comissao do Coordenador
         aAdd(_aProd2,0                      )// ZK2_COMIS2 - C6_COMIS2 - % de Comissao do Coordenador
         aAdd(_aProd ,TRANS(0,_cPictPER)     )// (_cAlias2)->C6_COMIS3 ZK2_COMIS3 - C6_COMIS3 - % de Comissao do Gerente
         aAdd(_aProd2,0                      )// ZK2_COMIS3 - C6_COMIS3 - % de Comissao do Gerente
         aAdd(_aProd ,TRANS(0,_cPictPER)     )// (_cAlias2)->C6_COMIS4 ZK2_COMIS4 - C6_COMIS4 - % de Comissao do Supervisor
         aAdd(_aProd2,0                      )// ZK2_COMIS4 - C6_COMIS4 - % de Comissao do Supervisor
         aAdd(_aProd ,TRANS(0,_cPictPER)     )// (_cAlias2)->C6_COMIS5 ZK2_COMIS5 - C6_COMIS5 - % de Comissao do Gerente Nacional
         aAdd(_aProd2,0                      )// ZK2_COMIS5 - C6_COMIS5 - % de Comissao do Gerente Nacional

         _nVrNetPED:= 0 //Round(((_cAlias2)->C6_VALOR-(_cAlias2)->C6_I_VLRDC)/(_cAlias2)->C6_QTDVEN,3)// (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO)/C6_QTDVEN // ZK2_NETPED
         
         //VALOR APURADO POR PEDIDO //////////////////////////////////////////////////////////////////////
         aAdd(_aProd ,TRANS(1 ,_cPictTOTAL))//(_cAlias2)->C6_VALOR VALOR APURADO     // ZK2_VRAPUR // VALOR PEDIDOS  - C6_VALOR
         aAdd(_aProd2,0) 
         //VALOR APURADO POR PEDIDO //////////////////////////////////////////////////////////////////////

         aAdd(_aProd ,TRANS(_nVrNetPED           ,_cPictVLNET))//Vr Net pedido     // ZK2_NETPED // (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO) / C6_QTDVEN 
         aAdd(_aProd2,_nVrNetPED) 
         aAdd(_aProd ,TRANS(_nVrNetPED           ,_cPictVLNET))//Vr Net ajustado   // ZK2_NETAJU // (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO) / C6_QTDVEN 
         aAdd(_aProd2,_nVrNetPED) 
         aAdd(_aProd ,TRANS(1,_cPictQTDE))//(_cAlias2)->C6_QTDVEN Qtde apurada 1UM  // ZK2_QAPU1U // C6_QTDVEN 
         aAdd(_aProd2,1) 
         aAdd(_aProd ,TRANS(1,_cPictQTDE))//(_cAlias2)->C6_UNSVEN Qtde apurada 2UM  // ZK2_QAPU2U // C6_UNSVEN 
         aAdd(_aProd2,1) 

         aAdd(_aProd ,0) //RATEIO
         aAdd(_aProd2,0) //RATEIO
         aAdd(_aProd ,0) //RECNO DO ALTERAR CASO PRECISE
         aAdd(_aProd2,0) //RECNO DO ALTERAR CASO PRECISE

         aAdd(_aProdMarca , _aProd  )//VALORES CARACTERES PARA MOSTRAR CORRETO - TELA DE MARCA E DESMARCA
         aAdd(_aProd2Marca, _aProd2 )//VALORES NUMERICOS PARA SOMAR OS MARCADOS
               
         /*      
         _aPreCont := aClone(_aProd)
         _aPreCont2:= aClone(_aProd2)

         _aProdMarca  :={}
         _aProd2Marca :={}

         aAdd(_aProdMarca , _aPreCont )//VALORES CARACTERES PARA MOSTRAR CORRETO - TELA DE MARCA E DESMARCA
         aAdd(_aProd2Marca, _aPreCont2 )//VALORES NUMERICOS PARA SOMAR OS MARCADOS
         */
      Next
   Else
      If Subs(MV_PAR19,1,1) = "2" .And.  Subs(MV_PAR17,1,2) <> "07" // PROVISAO = NAO ***************************************
         If oproc <> NIL
            oproc:cCaption := ("Filtrando pedidos ..." )
            ProcessMessages() 
         EndIf
         SC5->(DBSetOrder(1))
         SC6->(DBSetOrder(1))
         SB1->(DBSetOrder(1))
         Z24->(DBSetOrder(1))

         //CAMPOS SC5
         _cQuery := " SELECT C5_FILIAL,C5_NUM,C5_EMISSAO,C5_I_OPER, C5_CLIENTE,C5_LOJACLI,C5_I_NOME,C5_I_EST,C5_VEND1,C5_VEND2,C5_VEND3,C5_I_GRPVE, SC5.R_E_C_N_O_ SC5_REC, "
         //CAMPOS SC6
         _cQuery += " C6_PRODUTO,C6_DESCRI,C6_UNSVEN,C6_SEGUM,C6_VALOR, SC6.R_E_C_N_O_ SC6_REC, C6_QTDVEN, C6_I_PDESC,"
         _cQuery += " Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC ," // C6_I_VLRDESC, "
         _cQuery += " C6_COMIS1," //VENDEDOR
         _cQuery += " C6_COMIS2," //COORDENADOR
         _cQuery += " C6_COMIS3," //GERENTE
         _cQuery += " C6_COMIS4," //SUPERVISOR
         _cQuery += " C6_COMIS5," //GER_NACIONAL
         //CAMPO SD2 - FATURADO                                                                       
         _cQuery += " NVL(D2_EMISSAO,' ') D2_EMISSAO ,NVL(D2_DOC,' ') D2_DOC, NVL(D2_SERIE,' ') D2_SERIE, NVL(D2_QTSEGUM,0) D2_QTSEGUM ,NVL(D2_SEGUM,' ') D2_SEGUM, "
         _cQuery += " NVL(D2_FILIAL,' ') D2_FILIAL, NVL(D2_CLIENTE,' ') D2_CLIENTE, NVL(D2_LOJA,' ') D2_LOJA, NVL(D2_COD,' ') D2_COD, NVL(D2_ITEM,' ') D2_ITEM , "
         //           FATURADO-VLR_SEM_IMPOSTOS, FATURADO-VLR_COM_IMPOSTOS
         _cQuery += " NVL(D2_TOTAL,0) D2_TOTAL , NVL(D2_VALBRUT,0) VLRCOMIMP ,SD2.R_E_C_N_O_ SD2_REC,"
         _cQuery += " NVL(D2_QUANT,0) D2_QUANT , NVL(D2_I_VLRDC,0) VLRCONTRATO ,"
            
         //CAMPOS DE SUB SELECT DO SD1
         _cQuery += " (SELECT NVL(SUM ( (D1_QUANT)), 0) "
         _cQuery += "    FROM SD1010 SD1 "
         _cQuery += "   WHERE D1_FILIAL = D2_FILIAL "
         _cQuery += "     AND D1_FORNECE = D2_CLIENTE "
         _cQuery += "     AND D1_LOJA = D2_LOJA "
         _cQuery += "     AND D1_TIPO = 'D' "
         _cQuery += "     AND D1_DTDIGIT >= D2_EMISSAO "
         _cQuery += "     AND D1_NFORI = D2_DOC "
         _cQuery += "     AND D1_SERIORI = D2_SERIE "
         _cQuery += "     AND D1_COD = D2_COD "
         _cQuery += "     AND D1_ITEMORI = D2_ITEM "
         _cQuery += "     AND D1_TES <> ' ' "
         _cQuery += "     AND SD1.D_E_L_E_T_ = ' ') D1_QUANT, "//D1_QUANT    (D1_QUANT) (QTDE DEVOLUÇÃO 1UM)

         _cQuery += "(SELECT NVL(SUM ( (D1_QTSEGUM)), 0) "
         _cQuery += "    FROM SD1010 SD1 "
         _cQuery += "    WHERE     D1_FILIAL = D2_FILIAL "
         _cQuery += "         AND D1_FORNECE = D2_CLIENTE "
         _cQuery += "         AND D1_LOJA = D2_LOJA "
         _cQuery += "         AND D1_TIPO = 'D' "
         _cQuery += "         AND D1_DTDIGIT >= D2_EMISSAO "
         _cQuery += "         AND D1_NFORI = D2_DOC "
         _cQuery += "         AND D1_SERIORI = D2_SERIE "
         _cQuery += "         AND D1_COD = D2_COD "
         _cQuery += "         AND D1_ITEMORI = D2_ITEM "
         _cQuery += "         AND D1_TES <> ' ' "
         _cQuery += "         AND SD1.D_E_L_E_T_ = ' ') D1_QTSEGUM, " //D1_QTSEGUM  (D1_QTSEGUM) (QTDE DEVOLUÇÃO 2UM)

         _cQuery += " (SELECT NVL(SUM ( (D1_TOTAL - D1_VALDESC + D1_ICMSRET) ), 0) "
         _cQuery += " FROM SD1010 SD1 "
         _cQuery += " WHERE   D1_FILIAL = D2_FILIAL "
         _cQuery += "     AND D1_FORNECE = D2_CLIENTE "
         _cQuery += "     AND D1_LOJA = D2_LOJA "
         _cQuery += "     AND D1_TIPO = 'D' "
         _cQuery += "     AND D1_DTDIGIT >= D2_EMISSAO "
         _cQuery += "     AND D1_NFORI = D2_DOC "
         _cQuery += "     AND D1_SERIORI = D2_SERIE "
         _cQuery += "     AND D1_COD = D2_COD "
         _cQuery += "     AND D1_ITEMORI = D2_ITEM "
         _cQuery += "     AND D1_TES <> ' ' "
         _cQuery += "     AND SD1.D_E_L_E_T_ = ' ') DEVCOMIMP, "//DEVOLUCAO COM IMPOSTOS

         _cQuery += " (SELECT NVL(SUM ( (D1_TOTAL) ), 0) "
         _cQuery += " FROM SD1010 SD1 "
         _cQuery += " WHERE   D1_FILIAL = D2_FILIAL "
         _cQuery += "     AND D1_FORNECE = D2_CLIENTE "
         _cQuery += "     AND D1_LOJA = D2_LOJA "
         _cQuery += "     AND D1_TIPO = 'D' "
         _cQuery += "     AND D1_DTDIGIT >= D2_EMISSAO "
         _cQuery += "     AND D1_NFORI = D2_DOC "
         _cQuery += "     AND D1_SERIORI = D2_SERIE "
         _cQuery += "     AND D1_COD = D2_COD "
         _cQuery += "     AND D1_ITEMORI = D2_ITEM "
         _cQuery += "     AND D1_TES <> ' ' "
         _cQuery += "     AND SD1.D_E_L_E_T_ = ' ') D2_VALDEV,  "//DEVOLUCAO SEM IMPOSTOS

         _cQuery += " (SELECT NVL(SUM( (Round(D1_I_VLRDC,2))), 0)"
         _cQuery += " FROM SD1010 SD1"
         _cQuery += " WHERE     D1_FILIAL = D2_FILIAL"
         _cQuery += "       AND D1_FORNECE = D2_CLIENTE"
         _cQuery += "       AND D1_LOJA = D2_LOJA"
         _cQuery += "       AND D1_TIPO = 'D'"
         _cQuery += "       AND D1_DTDIGIT >= D2_EMISSAO"
         _cQuery += "       AND D1_NFORI = D2_DOC"
         _cQuery += "       AND D1_SERIORI = D2_SERIE"
         _cQuery += "       AND D1_COD = D2_COD"
         _cQuery += "       AND D1_ITEMORI = D2_ITEM "
         _cQuery += "       AND D1_TES <> ' '"
         _cQuery += "       AND SD1.D_E_L_E_T_ = ' ') DEVCONTRATO" //DEVCONTRATO (D1_I_VLRDC) (VALOR DO CONTRATO DEVOLUÇÃO)
         //CAMPOS DE SUB SELECT DO SD1

         If MV_PAR11 = "1" //NOTA //Forma de Apuracao: 1=Sobre Faturamento

            _cQuery += " 	FROM SD2010 SD2, SC6010 SC6, SC5010 SC5, SB1010 SB1, ZAY010 ZAY, SA1010 SA1 "
         
            _cQuery += "    WHERE D2_TIPO = 'N' "
            _cQuery += "      AND SC5.D_E_L_E_T_ = ' ' "
            _cQuery += "      AND C5_FILIAL = D2_FILIAL "
            _cQuery += "      AND C5_NUM = D2_PEDIDO"
            _cQuery += "      AND SC6.D_E_L_E_T_ = ' ' "
            _cQuery += "      AND B1_FILIAL = ' ' "
            _cQuery += "      AND B1_COD = D2_COD "
            _cQuery += "      AND B1_TIPO = 'PA' "
            _cQuery += "      AND SB1.D_E_L_E_T_ = ' ' "
            _cQuery += "      AND ZAY_FILIAL = ' ' "
            _cQuery += "      AND ZAY_CF = D2_CF "
            _cQuery += "      AND ZAY.D_E_L_E_T_ = ' ' "
            _cQuery += "      AND (ZAY_TPOPER = 'V' OR C5_I_OPER = '42') "
            _cQuery += "      AND D2_FILIAL = C6_FILIAL "
            _cQuery += "      AND C6_NUM = D2_PEDIDO
            _cQuery += "      AND D2_SERIE = C6_SERIE "
            _cQuery += "      AND D2_DOC = C6_NOTA "
            _cQuery += "      AND C6_PRODUTO = D2_COD "
            _cQuery += "      AND SD2.D_E_L_E_T_ = ' ' "

            _cQuery += "      AND A1_FILIAL = ' ' "
            _cQuery += "      AND A1_COD = C5_CLIENTE "
            _cQuery += "      AND A1_LOJA = C5_LOJACLI "
            _cQuery += "      AND SA1.D_E_L_E_T_ = ' ' "

            If !Empty(MV_PAR01)
               _cQuery += "  AND D2_EMISSAO >= '" + DToS(MV_PAR01)+"' "
            EndIf
            If !Empty(MV_PAR02)
               _cQuery += "  AND D2_EMISSAO <= '" + DToS(MV_PAR02)+"' "
            EndIf
         
         Else//POR PEDIDO //FORMA DE APURACAO: 2=SOBRE PEDIDO

            _cQuery += " 	FROM SC6010 SC6, SC5010 SC5, SD2010 SD2, SB1010 SB1, ZAY010 ZAY, SA1010 SA1 "
         
            _cQuery += "    WHERE C5_TIPO = 'N' "
            _cQuery += "      AND SC5.D_E_L_E_T_ = ' ' "
            _cQuery += "      AND C6_FILIAL = C5_FILIAL "
            _cQuery += "      AND C6_NUM = C5_NUM "
            _cQuery += "      AND SC6.D_E_L_E_T_ = ' ' "
            _cQuery += "      AND B1_FILIAL = ' ' "
            _cQuery += "      AND B1_COD = C6_PRODUTO "
            _cQuery += "      AND B1_TIPO = 'PA' "
            _cQuery += "      AND SB1.D_E_L_E_T_ = ' ' "
            _cQuery += "      AND ZAY_FILIAL = ' ' "
            _cQuery += "      AND ZAY_CF = C6_CF "
            _cQuery += "      AND ZAY.D_E_L_E_T_ = ' ' "
            _cQuery += "      AND (ZAY_TPOPER = 'V' OR C5_I_OPER = '42') "
            _cQuery += "      AND D2_FILIAL(+) = C6_FILIAL "
            _cQuery += "      AND D2_SERIE(+) = C6_SERIE "
            _cQuery += "      AND D2_DOC(+) = C6_NOTA "
            _cQuery += "      AND D2_COD(+) = C6_PRODUTO "
            _cQuery += "      AND SD2.D_E_L_E_T_(+) = ' ' "

            _cQuery += "      AND A1_FILIAL = ' ' "
            _cQuery += "      AND A1_COD = C5_CLIENTE "
            _cQuery += "      AND A1_LOJA = C5_LOJACLI "
            _cQuery += "      AND SA1.D_E_L_E_T_ = ' ' "

            If !Empty(MV_PAR01)//PEDIDOS
               _cQuery += "  AND C5_EMISSAO >= '" + DToS(MV_PAR01)+"' "
            EndIf
            If !Empty(MV_PAR02)//PEDIDOS
               _cQuery += "  AND C5_EMISSAO <= '" + DToS(MV_PAR02)+"' "
            EndIf
         
         EndIf
         
         If !Empty(MV_PAR03)
            If Len(AllTrim(MV_PAR03)) <= 2
               _cQuery += " AND C5_FILIAL = '"+ AllTrim(MV_PAR03) + "' "
            Else
               _cQuery += " AND C5_FILIAL IN " + FormatIn(AllTrim(MV_PAR03), ";") + " " 
            EndIf
         EndIf
         
         // Rede
         If !Empty( MV_PAR04 )                                                   
            If Len(AllTrim(MV_PAR04)) <= 6
               //_cQuery += " AND C5_I_GRPVE	= '" + AllTrim(MV_PAR04) + "' "
               _cQuery += " AND A1_GRPVEN 	= '" + AllTrim(MV_PAR04) + "' "
            Else
               //_cQuery += " AND C5_I_GRPVE	IN " + FormatIn( AllTrim(MV_PAR04) , ";" )
               _cQuery += " AND A1_GRPVEN 	IN " + FormatIn( AllTrim(MV_PAR04) , ";" )
            EndIf
         EndIf
         
         // CLIENTE
         If !Empty( MV_PAR05 )                                                   
            _cQuery += " AND C5_CLIENTE	= '" + AllTrim(MV_PAR05) + "' "
         EndIf
         
         // LOJA
         If !Empty( MV_PAR06 )                                                   
            _cQuery += " AND C5_LOJACLI	= '" + AllTrim(MV_PAR06) + "' "
         EndIf
         
         
         // Filtra Gerente
         If !Empty( MV_PAR07 )             
            If Len(AllTrim(MV_PAR07)) <= 6
               _cQuery += " AND C5_VEND3 = '"+ AllTrim(MV_PAR07) + "' "
            Else
               _cQuery += " AND C5_VEND3 IN "+ FormatIn( AllTrim(MV_PAR07) , ";" )
            EndIf
         EndIf
         
         // Filtra Coordenador
         If !Empty( MV_PAR08 )             
            If Len(AllTrim(MV_PAR08)) <= 6
               _cQuery += " AND C5_VEND2 = '"+ AllTrim(MV_PAR08) + "' "
            Else
               _cQuery += " AND C5_VEND2 IN "+ FormatIn( AllTrim(MV_PAR08) , ";" )
            EndIf
         EndIf
         
         // Filtra Vendedor
         If !Empty( MV_PAR09 )      
            If Len(AllTrim(MV_PAR09)) <= 6
               _cQuery += " AND C5_VEND1 = '"+ AllTrim(MV_PAR09) + "' "
            Else
               _cQuery += " AND C5_VEND1 IN "+ FormatIn(AllTrim(MV_PAR09), ";" )
            EndIf
         EndIf
         
         // Filtra Vendedor
         If !Empty( MV_PAR10 )      
            If Len(AllTrim(MV_PAR10)) <= 11
               _cQuery += " AND C6_PRODUTO = '"+ AllTrim(MV_PAR10) + "' "
            Else
               _cQuery += " AND C6_PRODUTO IN "+ FormatIn(AllTrim(MV_PAR10), ";" )
            EndIf
         EndIf

         // Filtra Pedido
         If !Empty( MV_PAR12 )      
            If Len(AllTrim(MV_PAR12)) <= Len(SC5->C5_NUM)
               _cQuery += " AND C5_NUM = '"+ AllTrim(MV_PAR12) + "' "
            Else
               _cQuery += " AND C5_NUM IN "+ FormatIn(AllTrim(MV_PAR12), ";" )
            EndIf
         EndIf

         //FILTRAR UF
         If !Empty( MV_PAR18 )      
            If Len(AllTrim(MV_PAR18)) <= Len(SC5->C5_I_EST)
               _cQuery += " AND C5_I_EST = '"+ AllTrim(MV_PAR18) + "' "
            Else
               _cQuery += " AND C5_I_EST IN "+ FormatIn(AllTrim(MV_PAR18), ";" )
            EndIf
         EndIf
         
         // Filtra BIMIX
         If !Empty( MV_PAR15 )      
            _cQuery += " AND B1_I_BIMIX IN "+ FormatIn(AllTrim(MV_PAR15), ";" )
         EndIf

         _cQuery += " ORDER BY C5_NUM , C6_PRODUTO "

         cTimeINI:=Time()
         
         MPSysOpenQuery( _cQuery , _cAlias2)
         
         DBSelectArea(_cAlias2)
         _nTot:=nConta:=0
         COUNT TO _nTot
         _cTotGeral:=AllTrim(Str(_nTot))

         cTimeFIM:="Hora Incial: "+cTimeINI+" - Hora Final: "+TIME()+" da leitura dos dados"

         (_cAlias2)->(DBGoTop())
         If (_cAlias2)->(Eof())
            U_ITMsg("Não tem pedidos para processamento com esses filtros.",cTimeFIM,"Altere os filtros.",3) 
            Return .F.
         EndIf
         
         If ValType(MV_PAR19) = "N"
            MV_PAR19 := AllTrim(Str(MV_PAR19))
         EndIf

         If Subs(MV_PAR19,1,1) = "2"
            If !U_ITMsg("Serão processados "+_cTotGeral+' Pedidos, Confirma ?',cTimeFIM,,3,2,3,,"CONFIRMA","VOLTAR")
               Return .F.
            EndIf
         EndIf

         ZK1->(DBSetOrder(1))//ZK1_FILIAL+ZK1_CODIGO
         ZK2->(DBSetOrder(2))//ZK2_FILIAL+ZK2_PEDFIL+ZK2_PEDIDO+ZK2_PRODUT
         SD1->(DBSetOrder(19))//D1_FILIAL+D1_NFORI+D1_SERIORI+D1_FORNECE+D1_LOJA

         aPedVin:={}
         While (_cAlias2)->(!Eof()) //**********************************  While  ******************************************************
               
            If oproc <> NIL
               nConta++
               oproc:cCaption := ("Lendo Ped.: "+(_cAlias2)->C5_FILIAL+(_cAlias2)->C5_NUM+" - "+StrZero(nConta,5) +" de "+ _cTotGeral )
               ProcessMessages()
            EndIf

            _aProd := {}//VALORES CARACTERES PARA MOSTRAR CORRETO
            _aProd2:= {}//VALORES NUMERICOS PARA SOMAR
                  
            aAdd(_aProd ,.F.) //01
            aAdd(_aProd2,.F.) //01

            If ZK2->(DBSeek(xFilial("ZK2")+(_cAlias2)->C5_FILIAL+(_cAlias2)->C5_NUM+(_cAlias2)->C6_PRODUTO+LEFT(MV_PAR16,1)))//Se achar o mesmo tipo NAO PODE MARCAR
               aAdd(_aProd ,.F.) //02
               aAdd(_aProd2,.F.) //02 

               npos := aScan( _aTiposAcor, {|x| Subs(x,1,1) = ZK2->ZK2_TIPOAC} ) 

               If nPos > 0
                  cDesc := _aTiposAcor[npos]
               Else
                  cDesc := ZK2->ZK2_TIPOAC
               EndIf
               aAdd(_aProd ,cDesc+" / "+ZK2->ZK2_CODIGO)//03
               aAdd(_aProd2,cDesc+" / "+ZK2->ZK2_CODIGO)//03 

            ElseIf ZK2->(DBSeek(xFilial("ZK2")+(_cAlias2)->C5_FILIAL+(_cAlias2)->C5_NUM+(_cAlias2)->C6_PRODUTO))//SE Achar outro tipo qq PODE MARCAR
         
               aAdd(_aProd ,.T.) //02
               aAdd(_aProd2,.T.) //02

               npos := aScan( _aTiposAcor, {|x| Subs(x,1,1) = ZK2->ZK2_TIPOAC} ) 

               If nPos > 0
                  cDesc := _aTiposAcor[npos]
               Else
                  cDesc := ZK2->ZK2_TIPOAC
               EndIf
               aAdd(_aProd ,cDesc+" / "+ZK2->ZK2_CODIGO)//03
               aAdd(_aProd2,cDesc+" / "+ZK2->ZK2_CODIGO)//03 

            Else//Se não achar PODE MARCAR
               aAdd(_aProd ,.T.) //02
               aAdd(_aProd2,.T.) //02
               aAdd(_aProd ,MV_PAR16)//03
               aAdd(_aProd2,MV_PAR16)//03 
            EndIf

            aAdd(_aProd ,(_cAlias2)->C5_FILIAL)
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            
            aAdd(_aProd ,(_cAlias2)->C5_NUM)
            aAdd(_aProd2,_aProd[Len(_aProd)]) 

            If MV_PAR11 = "1" //NOTA //Forma de Apuracao: 1=Sobre Faturamento
               aAdd(_aProd ,(_cAlias2)->(D2_DOC+"-"+D2_SERIE))//_nPosNF
               aAdd(_aProd2,_aProd[Len(_aProd)]) //06 

               aAdd(_aProd ,SToD((_cAlias2)->D2_EMISSAO))//POR NOTA
               aAdd(_aProd2,_aProd[Len(_aProd)]) //07

            Else//If MV_PAR11 = "2" //PEDIDOS //FORMA DE APURACAO: 2=SOBRE PEDIDO
               aAdd(_aProd ,SToD((_cAlias2)->C5_EMISSAO))//POR PEDIDO
               aAdd(_aProd2,_aProd[Len(_aProd)])//06

               aAdd(_aProd ,(_cAlias2)->(D2_DOC+"-"+D2_SERIE))//_nPosNF
               aAdd(_aProd2,_aProd[Len(_aProd)])//07
            EndIf

            aAdd(_aProd ,(_cAlias2)->C6_PRODUTO)//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 

            aAdd(_aProd ,(_cAlias2)->C6_DESCRI)//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 

            aAdd(_aProd ,Posicione("SB1",1,xFilial ("SB1")+(_cAlias2)->C6_PRODUTO ,"B1_I_BIMIX")) //
            aAdd(_aProd2,_aProd[Len(_aProd)]) 

            aAdd(_aProd ,(_cAlias2)->C5_I_OPER+"-"+Posicione("ZB4",1,xFilial("ZB4")+(_cAlias2)->C5_I_OPER, "ZB4_DESCRI"))//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            aAdd(_aProd ,(_cAlias2)->C5_CLIENTE)//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            aAdd(_aProd ,(_cAlias2)->C5_LOJACLI)//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            aAdd(_aProd ,(_cAlias2)->C5_I_NOME)//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            aAdd(_aProd ,(_cAlias2)->C5_I_EST)//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            aAdd(_aProd ,(_cAlias2)->C5_VEND1+"-"+Posicione("SA3",1,xFilial("SA3")+(_cAlias2)->C5_VEND1,"A3_NOME"))//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            aAdd(_aProd ,(_cAlias2)->C5_VEND2+"-"+Posicione("SA3",1,xFilial("SA3")+(_cAlias2)->C5_VEND2,"A3_NOME"))//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            aAdd(_aProd ,(_cAlias2)->C5_VEND3+"-"+Posicione("SA3",1,xFilial("SA3")+(_cAlias2)->C5_VEND3,"A3_NOME"))//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            aAdd(_aProd ,(_cAlias2)->C5_I_GRPVE)//
            aAdd(_aProd2,_aProd[Len(_aProd)]) 

            aAdd(_aProd ,TRANS((_cAlias2)->C6_UNSVEN,_cPictQTDE))//Qtde. Pedido (2a) - C6_UNSVEN - ZK2_QPED2U
            aAdd(_aProd2,(_cAlias2)->C6_UNSVEN) 
            
            aAdd(_aProd ,(_cAlias2)->C6_SEGUM)//UM (2a) - C6_SEGUM - ZK2_UNIDAD
            aAdd(_aProd2,_aProd[Len(_aProd)]) 
            
            aAdd(_aProd ,TRANS((_cAlias2)->C6_VALOR,_cPictVALOR))//Valor pedido - C6_VALOR - ZK2_VRPEDI
            aAdd(_aProd2,(_cAlias2)->C6_VALOR) 
            
            aAdd(_aProd ,TRANS((_cAlias2)->D2_QTSEGUM,_cPictQTSEG))//
            aAdd(_aProd2,(_cAlias2)->D2_QTSEGUM) 
            
            aAdd(_aProd ,(_cAlias2)->D2_SEGUM)
            aAdd(_aProd2,(_cAlias2)->D2_SEGUM) 
            
            // C6_QTDVEN   (QUANTIDADE DO PEDIDO 1 UM)
            // C6_I_PDESC  (PERCENTUAL DE DESCONTO CONTRATUAL)
            // C6_I_VLRDC  (VALOR DO DESCONTO CONTRATUAL DO PEDIDO) (Calculo)
            // D2_QUANT    (QUANTIDADE FATURADA 1 UM)
            // D2_VALBRUT  (VLRCOMIMP VALOR FATURADO COM IMPOSTOS)
            // D2_I_VLRDC  (VLRCONTRATO, VALOR DO DESCONTO CONTRATUAL FATURADO)
            // D1_QUANT    (D1_QUANT) (QTDE DEVOLUÇÃO 1UM)
            // D1_QTSEGUM  (D1_QTSEGUM) (QTDE DEVOLUÇÃO 2UM)
            // DEVCOMIMP   (D1_TOTAL - D1_VALDESC + D1_ICMSRET) (VR DEVOLUÇÃO COM IMPOSTOS)
            // DEVCONTRATO (D1_I_VLRDC) (VALOR DO CONTRATO DEVOLUÇÃO)

            aAdd(_aProd ,TRANS(((_cAlias2)->D2_TOTAL),_cPictTOTAL))  // ZK2_VRFATM - (Vr fat s/ impostos) (USADO NO RATEIO)
            aAdd(_aProd2,(_cAlias2)->D2_TOTAL)                       // ZK2_VRFATM - (Vr fat s/ impostos) (USADO NO RATEIO)

            aAdd(_aProd ,TRANS((_cAlias2)->C6_QTDVEN,_cPictQTDE)    )// ZK2_QPED1U - (Quantidade do pedido 1 UM)
            aAdd(_aProd2,(_cAlias2)->C6_QTDVEN                      )// ZK2_QPED1U - (Quantidade do pedido 1 UM)

            aAdd(_aProd ,TRANS((_cAlias2)->C6_I_PDESC,_cPictPER)    )// ZK2_PECTPE - (Percentual de desconto contratual)
            aAdd(_aProd2,(_cAlias2)->C6_I_PDESC                     )// ZK2_PECTPE - (Percentual de desconto contratual)

            aAdd(_aProd ,TRANS((_cAlias2)->C6_I_VLRDC,_cPictVALOR)  )// ZK2_VRCTPE - (Valor do desconto contratual do pedido) (Calculo na SELECT (Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC) )
            aAdd(_aProd2,(_cAlias2)->C6_I_VLRDC                     )// ZK2_VRCTPE - (Valor do desconto contratual do pedido) (Calculo na SELECT (Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC) )
            
            aAdd(_aProd ,TRANS((_cAlias2)->D2_QUANT    ,_cPictQTDE) )// ZK2_QFAT1U - (Quantidade faturada 1 UM)
            aAdd(_aProd2,(_cAlias2)->D2_QUANT                       )// ZK2_QFAT1U - (Quantidade faturada 1 UM)
            
            aAdd(_aProd ,TRANS((_cAlias2)->VLRCOMIMP  ,_cPictVALOR) )// ZK2_VRFATI - (VLRCOMIMP valor faturado com impostos)
            aAdd(_aProd2,(_cAlias2)->VLRCOMIMP                      )// ZK2_VRFATI - (VLRCOMIMP valor faturado com impostos)
            
            aAdd(_aProd ,TRANS((_cAlias2)->VLRCONTRATO ,_cPictVALOR))// ZK2_VRCTFA - (VLRCONTRATO, Valor do desconto contratual faturado)
            aAdd(_aProd2,(_cAlias2)->VLRCONTRATO                    )// ZK2_VRCTFA - (VLRCONTRATO, Valor do desconto contratual faturado)

            //CAMPOS DE SUB SELECT DO SD1      
            _nD1_QUANT   :=(_cAlias2)->D1_QUANT 
            _nD1_QTSEGUM :=(_cAlias2)->D1_QTSEGUM
            _nD2_VALDEV  :=(_cAlias2)->D2_VALDEV
            _nDEVCOMIMP  :=(_cAlias2)->DEVCOMIMP
            _nDEVCONTRATO:=(_cAlias2)->DEVCONTRATO

            aAdd(_aProd ,TRANS(_nD1_QUANT    ,_cPictQTDE))// ZK2_QDEV1U  - SD1 - (Qtde devolução 1UM)
            aAdd(_aProd2,_nD1_QUANT                      )// ZK2_QDEV1U  - SD1 - (Qtde devolução 1UM)
            
            aAdd(_aProd ,TRANS(_nD1_QTSEGUM  ,_cPictQTDE))// ZK2_QDEV2U  - SD1 - (Qtde devolução 2UM)
            aAdd(_aProd2,_nD1_QTSEGUM                    )// ZK2_QDEV2U  - SD1 - (Qtde devolução 2UM)
            
            aAdd(_aProd ,TRANS(_nD2_VALDEV,_cPictVALDE)  )// ZK2_VRDEVM  - SD1 - Vr devolução SEM impostos) (D1_TOTAL)
            aAdd(_aProd2,_nD2_VALDEV                     )// ZK2_VRDEVM  - SD1 - (Vr devolução SEM impostos) (D1_TOTAL)

            aAdd(_aProd ,TRANS(_nDEVCOMIMP  ,_cPictVALOR))// ZK2_VRDEVI - SD1 - (Vr devolução com impostos) (D1_TOTAL - D1_VALDESC + D1_ICMSRET)
            aAdd(_aProd2,_nDEVCOMIMP                     )// ZK2_VRDEVI - SD1 - (Vr devolução com impostos) (D1_TOTAL - D1_VALDESC + D1_ICMSRET)
            
            aAdd(_aProd ,TRANS(_nDEVCONTRATO ,_cPictVALOR))// ZK2_VRCTDE - SD1 - (Valor do contrato devolução)
            aAdd(_aProd2,_nDEVCONTRATO                   )// ZK2_VRCTDE - SD1 - (Valor do contrato devolução)

            //CAMPOS DE SUB SELECT DO SD1      
            aAdd(_aProd ,TRANS((_cAlias2)->C6_COMIS1,_cPictPER)     )// ZK2_COMIS1 - C6_COMIS1 - % de Comissao do Vendedor
            aAdd(_aProd2,(_cAlias2)->C6_COMIS1                      )// ZK2_COMIS1 - C6_COMIS1 - % de Comissao do Vendedor
            aAdd(_aProd ,TRANS((_cAlias2)->C6_COMIS2,_cPictPER)     )// ZK2_COMIS2 - C6_COMIS2 - % de Comissao do Coordenador
            aAdd(_aProd2,(_cAlias2)->C6_COMIS2                      )// ZK2_COMIS2 - C6_COMIS2 - % de Comissao do Coordenador
            aAdd(_aProd ,TRANS((_cAlias2)->C6_COMIS3,_cPictPER)     )// ZK2_COMIS3 - C6_COMIS3 - % de Comissao do Gerente
            aAdd(_aProd2,(_cAlias2)->C6_COMIS3                      )// ZK2_COMIS3 - C6_COMIS3 - % de Comissao do Gerente
            aAdd(_aProd ,TRANS((_cAlias2)->C6_COMIS4,_cPictPER)     )// ZK2_COMIS4 - C6_COMIS4 - % de Comissao do Supervisor
            aAdd(_aProd2,(_cAlias2)->C6_COMIS4                      )// ZK2_COMIS4 - C6_COMIS4 - % de Comissao do Supervisor
            aAdd(_aProd ,TRANS((_cAlias2)->C6_COMIS5,_cPictPER)     )// ZK2_COMIS5 - C6_COMIS5 - % de Comissao do Gerente Nacional
            aAdd(_aProd2,(_cAlias2)->C6_COMIS5                      )// ZK2_COMIS5 - C6_COMIS5 - % de Comissao do Gerente Nacional

            _nVrNetPED:=Round(((_cAlias2)->C6_VALOR-(_cAlias2)->C6_I_VLRDC)/(_cAlias2)->C6_QTDVEN,3)// (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO)/C6_QTDVEN // ZK2_NETPED
            
            If MV_PAR11 = "1"//POR NOTA  //Forma de Apuracao: 1=Sobre Faturamento

               //VALOR APURADO POR NOTA /////////////////////////////////////////////////////////////////////////////
               nTirDEvolucao:=0//ZERO NAÕ TIRA O VALOR DA DEVOLUCAO
               If MV_PAR14 = "1"//TIRA O VALOR DA DEVOLULCAO 
                  If MV_PAR13 = "1" //COM IMPOSTO 
                     nTirDevolucao:=_nDEVCOMIMP
                  Else              //SEM IMPOSTOS
                     nTirDevolucao:=_nD2_VALDEV
                  EndIf
               EndIf
            
               If MV_PAR13 = "1" //COM IMPOSTO - ZK2_VRAPUR
                  aAdd(_aProd ,TRANS(((_cAlias2)->VLRCOMIMP-nTirDEvolucao),_cPictTOTAL))
                  aAdd(_aProd2,(_cAlias2)->VLRCOMIMP-nTirDEvolucao) 
               Else             //SEM IMPOSTOS - ZK2_VRAPUR
                  aAdd(_aProd ,TRANS(((_cAlias2)->D2_TOTAL-nTirDEvolucao),_cPictTOTAL))
                  aAdd(_aProd2,(_cAlias2)->D2_TOTAL-nTirDEvolucao) 
               EndIf
               //VALOR APURADO POR NOTA //////////////////////////////////////////////////////////////////////

               aAdd(_aProd ,TRANS(_nVrNetPED,_cPictVLNET))//VR NET PEDIDO // ZK2_NETPED // (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO) / C6_QTDVEN 
               aAdd(_aProd2,_nVrNetPED) 
               
               _nQtdeApur1um:=((_cAlias2)->D2_QUANT - _nD1_QUANT)
               
               _nVrNetAjus:=Round( ( (_cAlias2)->D2_TOTAL-_nD2_VALDEV-((_cAlias2)->VLRCONTRATO-_nDEVCONTRATO) ) / _nQtdeApur1um ,3) //(VR FAT S/ IMP - VR DEV S/ IMP - D2_I_VLRDC - D1_I_VLRDC - RATEIO) / (QTDE FAT 1UM - QTDE DEV 1 UM)

               aAdd(_aProd ,TRANS(_nVrNetAjus,_cPictVLNET))//Vr Net ajustado   - ZK2_NETAJU - (VR FAT S/ IMP - VR DEV S/ IMP)   /(QTDE FAT 1UM - QTDE DEV 1 UM)
               aAdd(_aProd2,_nVrNetAjus) 

               aAdd(_aProd ,TRANS(_nQtdeApur1um,_cPictQTDE))    //Qtde apurada 1UM  - ZK2_QAPU1U // (D2_QUANT  - D1_QUANT)
               aAdd(_aProd2,_nQtdeApur1um) 

               aAdd(_aProd ,TRANS(((_cAlias2)->D2_QTSEGUM - _nD1_QTSEGUM),_cPictQTDE))//Qtde apurada 2UM  - ZK2_QAPU2U // (D2_QTSEGUM - D1_QTSEGUM)
               aAdd(_aProd2,((_cAlias2)->D2_QTSEGUM - _nD1_QTSEGUM)) 

            Else//POR PEDIDO

               //VALOR APURADO POR PEDIDO //////////////////////////////////////////////////////////////////////
               aAdd(_aProd ,TRANS((_cAlias2)->C6_VALOR ,_cPictTOTAL))//VALOR APURADO     // ZK2_VRAPUR // VALOR PEDIDOS  - C6_VALOR
               aAdd(_aProd2,(_cAlias2)->C6_VALOR) 
               //VALOR APURADO POR PEDIDO //////////////////////////////////////////////////////////////////////

               aAdd(_aProd ,TRANS(_nVrNetPED           ,_cPictVLNET))//Vr Net pedido     // ZK2_NETPED // (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO) / C6_QTDVEN 
               aAdd(_aProd2,_nVrNetPED) 
               aAdd(_aProd ,TRANS(_nVrNetPED           ,_cPictVLNET))//Vr Net ajustado   // ZK2_NETAJU // (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO) / C6_QTDVEN 
               aAdd(_aProd2,_nVrNetPED) 
               aAdd(_aProd ,TRANS((_cAlias2)->C6_QTDVEN,_cPictQTDE))//Qtde apurada 1UM  // ZK2_QAPU1U // C6_QTDVEN 
               aAdd(_aProd2,(_cAlias2)->C6_QTDVEN) 
               aAdd(_aProd ,TRANS((_cAlias2)->C6_UNSVEN,_cPictQTDE))//Qtde apurada 2UM  // ZK2_QAPU2U // C6_UNSVEN 
               aAdd(_aProd2,(_cAlias2)->C6_UNSVEN) 

            EndIf

            aAdd(_aProd ,0) //RATEIO
            aAdd(_aProd2,0) //RATEIO
            aAdd(_aProd ,0) //RECNO DO ALTERAR CASO PRECISE
            aAdd(_aProd2,0) //RECNO DO ALTERAR CASO PRECISE
         
            aAdd(_aProdMarca , _aProd  )//VALORES CARACTERES PARA MOSTRAR CORRETO - TELA DE MARCA E DESMARCA
            aAdd(_aProd2Marca, _aProd2 )//VALORES NUMERICOS PARA SOMAR OS MARCADOS
                  
            (_cAlias2)->(DBSkip())
         
         EndDo

         (_cAlias2)->(DBCloseArea())

      Else//If Subs(MV_PAR19,1,1) = "1" // PROVISAO = SIM  *****************************************************************

         _aProd := {}//VALORES CARACTERES PARA MOSTRAR CORRETO
         _aProd2:= {}//VALORES NUMERICOS PARA SOMAR

         aAdd(_aProd ,.F.) //01
         aAdd(_aProd2,.F.) //01
         aAdd(_aProd ,.T.) //02
         aAdd(_aProd2,.T.) //02

         aAdd(_aProd ,MV_PAR16)//03
         aAdd(_aProd2,MV_PAR16)//03 

         aAdd(_aProd ,xFilial("SC5"))
         aAdd(_aProd2,_aProd[Len(_aProd)]) //04
         
         aAdd(_aProd ,Space(Len(SC5->C5_NUM)))
         aAdd(_aProd2,_aProd[Len(_aProd)]) //05

         If (_nOpc = 3  .And. MV_PAR11 = "1") .Or. (_nOpc <> 3  .And. ZK1->ZK1_FORAPU = "1") .Or. Subs(MV_PAR19,1,1) = "1" 
            aAdd(_aProd ,Space(Len(SD2->(D2_DOC+"-"+D2_SERIE))))//_nPosNF
            aAdd(_aProd2,_aProd[Len(_aProd)])  //06

            aAdd(_aProd ,SToD(""))//D2_EMISSAO
            aAdd(_aProd2,_aProd[Len(_aProd)]) //07
         Else
            aAdd(_aProd ,SToD(""))//D2_EMISSAO
            aAdd(_aProd2,_aProd[Len(_aProd)]) //06

            aAdd(_aProd ,Space(Len(SD2->(D2_DOC+"-"+D2_SERIE))))//_nPosNF
            aAdd(_aProd2,_aProd[Len(_aProd)])  //07
         EndIf

         aAdd(_aProd ,"XXXXXXXXXXXXX")//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //08

         aAdd(_aProd , "PROVISAO")//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //09

         aAdd(_aProd , "")//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //10

         aAdd(_aProd ,Space(Len(SC5->C5_I_OPER)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //11

         aAdd(_aProd ,Space(Len(SC5->C5_CLIENTE)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //12
         
         aAdd(_aProd ,Space(Len(SC5->C5_LOJACLI)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //13
         
         aAdd(_aProd ,Space(Len(SC5->C5_I_NOME)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //14
         
         aAdd(_aProd ,Space(Len(SC5->C5_I_EST)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //15
         
         aAdd(_aProd ,"")// ->C5_VEND1+"-"+Posicione("SA3",1,xFilial("SA3")+(_cAlias2)->C5_VEND1,"A3_NOME")
         aAdd(_aProd2,_aProd[Len(_aProd)]) //16
         
         aAdd(_aProd ,"")// (_cAlias2)->C5_VEND2+"-"+Posicione("SA3",1,xFilial("SA3")+(_cAlias2)->C5_VEND2,"A3_NOME")
         aAdd(_aProd2,_aProd[Len(_aProd)]) //17
         
         aAdd(_aProd ,"")//(_cAlias2)->C5_VEND3+"-"+Posicione("SA3",1,xFilial("SA3")+(_cAlias2)->C5_VEND3,"A3_NOME")
         aAdd(_aProd2,_aProd[Len(_aProd)]) //18
         
         aAdd(_aProd ,Space(Len(SC5->C5_I_GRPVE)))//
         aAdd(_aProd2,_aProd[Len(_aProd)]) //19

         aAdd(_aProd ,TRANS(1,_cPictQTDE))//_cAlias2)->C6_UNSVEN
         aAdd(_aProd2,1) //20
         
         aAdd(_aProd ,"KG")//(_cAlias2)->C6_SEGUM
         aAdd(_aProd2,_aProd[Len(_aProd)]) //21
         
         aAdd(_aProd ,TRANS(1,_cPictVALOR))//Valor pedido - (_cAlias2)->C6_VALORI
         aAdd(_aProd2,1) //22
         
         aAdd(_aProd ,TRANS(1,_cPictQTSEG))//(_cAlias2)->D2_QTSEGUM
         aAdd(_aProd2,1) //23
         
         aAdd(_aProd ,"KG") //(_cAlias2)->D2_SEGUM
         aAdd(_aProd2,"KG")//24
         
         // C6_QTDVEN   (QUANTIDADE DO PEDIDO 1 UM)
         // C6_I_PDESC  (PERCENTUAL DE DESCONTO CONTRATUAL)
         // C6_I_VLRDC  (VALOR DO DESCONTO CONTRATUAL DO PEDIDO) (Calculo)
         // D2_QUANT    (QUANTIDADE FATURADA 1 UM)
         // D2_VALBRUT  (VLRCOMIMP VALOR FATURADO COM IMPOSTOS)
         // D2_I_VLRDC  (VLRCONTRATO, VALOR DO DESCONTO CONTRATUAL FATURADO)
         // D1_QUANT    (D1_QUANT) (QTDE DEVOLUÇÃO 1UM)
         // D1_QTSEGUM  (D1_QTSEGUM) (QTDE DEVOLUÇÃO 2UM)
         // DEVCOMIMP   (D1_TOTAL - D1_VALDESC + D1_ICMSRET) (VR DEVOLUÇÃO COM IMPOSTOS)
         // DEVCONTRATO (D1_I_VLRDC) (VALOR DO CONTRATO DEVOLUÇÃO)

         aAdd(_aProd ,TRANS(1,_cPictTOTAL))  // (_cAlias2)->D2_TOTAL ZK2_VRFATM - (Vr fat s/ impostos) (USADO NO RATEIO)
         aAdd(_aProd2,1)                       // ZK2_VRFATM - (Vr fat s/ impostos) (USADO NO RATEIO) 

         aAdd(_aProd ,TRANS(1,_cPictQTDE)    )// (_cAlias2)->C6_QTDVEN ZK2_QPED1U - (Quantidade do pedido 1 UM)
         aAdd(_aProd2,1                      )// ZK2_QPED1U - (Quantidade do pedido 1 UM)

         aAdd(_aProd ,TRANS(0,_cPictPER)    )// (_cAlias2)->C6_I_PDESC ZK2_PECTPE - (Percentual de desconto contratual)
         aAdd(_aProd2,0                     )//(_cAlias2)->C6_I_PDESC ZK2_PECTPE - (Percentual de desconto contratual)

         aAdd(_aProd ,TRANS(0,_cPictVALOR)  )//(_cAlias2)->C6_I_VLRDC ZK2_VRCTPE - (Valor do desconto contratual do pedido) (Calculo na SELECT (Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC) )
         aAdd(_aProd2,0                    )// ZK2_VRCTPE - (Valor do desconto contratual do pedido) (Calculo na SELECT (Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC) )
         
         aAdd(_aProd ,TRANS(1    ,_cPictQTDE) )//(_cAlias2)->D2_QUANT ZK2_QFAT1U - (Quantidade faturada 1 UM)
         aAdd(_aProd2,1                       )// ZK2_QFAT1U - (Quantidade faturada 1 UM)
         
         aAdd(_aProd ,TRANS(0  ,_cPictVALOR) )//(_cAlias2)->VLRCOMIMP ZK2_VRFATI - (VLRCOMIMP valor faturado com impostos)
         aAdd(_aProd2,0                     )// ZK2_VRFATI - (VLRCOMIMP valor faturado com impostos)
         
         aAdd(_aProd ,TRANS(1 ,_cPictVALOR))// (_cAlias2)->VLRCONTRATO ZK2_VRCTFA - (VLRCONTRATO, Valor do desconto contratual faturado)
         aAdd(_aProd2,1                    )// ZK2_VRCTFA - (VLRCONTRATO, Valor do desconto contratual faturado)

         //CAMPOS DE SUB SELECT DO SD1      
         _nD1_QUANT    := 1 //(_cAlias2)->D1_QUANT 
         _nD1_QTSEGUM  := 1 //(_cAlias2)->D1_QTSEGUM
         _nD2_VALDEV   := 0 //(_cAlias2)->D2_VALDEV
         _nDEVCOMIMP   := 0 //(_cAlias2)->DEVCOMIMP
         _nDEVCONTRATO := 0 //(_cAlias2)->DEVCONTRATO

         aAdd(_aProd ,TRANS(_nD1_QUANT    ,_cPictQTDE))// ZK2_QDEV1U  - SD1 - (Qtde devolução 1UM)
         aAdd(_aProd2,_nD1_QUANT                      )// ZK2_QDEV1U  - SD1 - (Qtde devolução 1UM)
         
         aAdd(_aProd ,TRANS(_nD1_QTSEGUM  ,_cPictQTDE))// ZK2_QDEV2U  - SD1 - (Qtde devolução 2UM)
         aAdd(_aProd2,_nD1_QTSEGUM                    )// ZK2_QDEV2U  - SD1 - (Qtde devolução 2UM)
         
         aAdd(_aProd ,TRANS(_nD2_VALDEV,_cPictVALDE)  )// ZK2_VRDEVM  - SD1 - Vr devolução SEM impostos) (D1_TOTAL)
         aAdd(_aProd2,_nD2_VALDEV                     )// ZK2_VRDEVM  - SD1 - (Vr devolução SEM impostos) (D1_TOTAL)

         aAdd(_aProd ,TRANS(_nDEVCOMIMP  ,_cPictVALOR))// ZK2_VRDEVI - SD1 - (Vr devolução com impostos) (D1_TOTAL - D1_VALDESC + D1_ICMSRET)
         aAdd(_aProd2,_nDEVCOMIMP                     )// ZK2_VRDEVI - SD1 - (Vr devolução com impostos) (D1_TOTAL - D1_VALDESC + D1_ICMSRET)
         
         aAdd(_aProd ,TRANS(_nDEVCONTRATO ,_cPictVALOR))// ZK2_VRCTDE - SD1 - (Valor do contrato devolução)
         aAdd(_aProd2,_nDEVCONTRATO                   )// ZK2_VRCTDE - SD1 - (Valor do contrato devolução)

         //CAMPOS DE SUB SELECT DO SD1      
         aAdd(_aProd ,TRANS(0,_cPictPER)     )//(_cAlias2)->C6_COMIS1 ZK2_COMIS1 - C6_COMIS1 - % de Comissao do Vendedor
         aAdd(_aProd2,0                      )// ZK2_COMIS1 - C6_COMIS1 - % de Comissao do Vendedor
         aAdd(_aProd ,TRANS(0,_cPictPER)     )// (_cAlias2)->C6_COMIS2 ZK2_COMIS2 - C6_COMIS2 - % de Comissao do Coordenador
         aAdd(_aProd2,0                      )// ZK2_COMIS2 - C6_COMIS2 - % de Comissao do Coordenador
         aAdd(_aProd ,TRANS(0,_cPictPER)     )// (_cAlias2)->C6_COMIS3 ZK2_COMIS3 - C6_COMIS3 - % de Comissao do Gerente
         aAdd(_aProd2,0                      )// ZK2_COMIS3 - C6_COMIS3 - % de Comissao do Gerente
         aAdd(_aProd ,TRANS(0,_cPictPER)     )// (_cAlias2)->C6_COMIS4 ZK2_COMIS4 - C6_COMIS4 - % de Comissao do Supervisor
         aAdd(_aProd2,0                      )// ZK2_COMIS4 - C6_COMIS4 - % de Comissao do Supervisor
         aAdd(_aProd ,TRANS(0,_cPictPER)     )// (_cAlias2)->C6_COMIS5 ZK2_COMIS5 - C6_COMIS5 - % de Comissao do Gerente Nacional
         aAdd(_aProd2,0                      )// ZK2_COMIS5 - C6_COMIS5 - % de Comissao do Gerente Nacional

         _nVrNetPED:= 1 //Round(((_cAlias2)->C6_VALOR-(_cAlias2)->C6_I_VLRDC)/(_cAlias2)->C6_QTDVEN,3)// (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO)/C6_QTDVEN // ZK2_NETPED
         
         //VALOR APURADO POR PEDIDO //////////////////////////////////////////////////////////////////////
         aAdd(_aProd ,TRANS(1 ,_cPictTOTAL))//(_cAlias2)->C6_VALOR VALOR APURADO     // ZK2_VRAPUR // VALOR PEDIDOS  - C6_VALOR
         aAdd(_aProd2,1) 
         //VALOR APURADO POR PEDIDO //////////////////////////////////////////////////////////////////////

         aAdd(_aProd ,TRANS(_nVrNetPED           ,_cPictVLNET))//Vr Net pedido     // ZK2_NETPED // (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO) / C6_QTDVEN 
         aAdd(_aProd2,_nVrNetPED) 
         aAdd(_aProd ,TRANS(_nVrNetPED           ,_cPictVLNET))//Vr Net ajustado   // ZK2_NETAJU // (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO) / C6_QTDVEN 
         aAdd(_aProd2,_nVrNetPED) 
         aAdd(_aProd ,TRANS(1,_cPictQTDE))//(_cAlias2)->C6_QTDVEN Qtde apurada 1UM  // ZK2_QAPU1U // C6_QTDVEN 
         aAdd(_aProd2,1) 
         aAdd(_aProd ,TRANS(1,_cPictQTDE))//(_cAlias2)->C6_UNSVEN Qtde apurada 2UM  // ZK2_QAPU2U // C6_UNSVEN 
         aAdd(_aProd2,1) 

         aAdd(_aProd ,0) //RATEIO
         aAdd(_aProd2,0) //RATEIO
         aAdd(_aProd ,0) //RECNO DO ALTERAR CASO PRECISE
         aAdd(_aProd2,0) //RECNO DO ALTERAR CASO PRECISE

         _aPreCont := aClone(_aProd)
         _aPreCont2:= aClone(_aProd2)

         _aProdMarca  :={}
         _aProd2Marca :={}

         aAdd(_aProdMarca , _aPreCont )//VALORES CARACTERES PARA MOSTRAR CORRETO - TELA DE MARCA E DESMARCA
         aAdd(_aProd2Marca, _aPreCont2 )//VALORES NUMERICOS PARA SOMAR OS MARCADOS
      EndIf
   EndIf
    

   If Len(_aProdMarca) < 1
      U_ITMsg("Não tem pedidos para processamento para esse Tipo de Acordo: "+CHR(13)+CHR(10)+MV_PAR16,'Atenção!',"Altere os filtros.",3) 
      Return .F.
   EndIf

   _cMsgFil:="Emissão de: "          +AllTrim(AllToChar(MV_PAR01))+" ate "+AllTrim(AllToChar(MV_PAR02))+_ENTER+;
           "Filiais: "             +AllTrim(AllToChar(MV_PAR03))+_ENTER+;
           "Redes: "               +AllTrim(AllToChar(MV_PAR04))+_ENTER+;
           "Cliente: "             +AllTrim(AllToChar(MV_PAR05))+_ENTER+;
           "Loja: "                +AllTrim(AllToChar(MV_PAR06))+_ENTER+;
           "Gerente: "             +AllTrim(AllToChar(MV_PAR07))+_ENTER+;
           "Coordenador: "         +AllTrim(AllToChar(MV_PAR08))+_ENTER+;
           "Vendedor: "            +AllTrim(AllToChar(MV_PAR09))+_ENTER+;
           "Produtos: "            +AllTrim(AllToChar(MV_PAR10))+_ENTER+;
           "Filtrar por: "         +AllTrim(AllToChar(MV_PAR11))+_ENTER+;
           "Pedidos: "             +AllTrim(AllToChar(MV_PAR12))+_ENTER+;
           "Somar Impostos: "      +AllTrim(AllToChar(MV_PAR13))+_ENTER+;
           "Considerar Devolucao: "+AllTrim(AllToChar(MV_PAR14))+_ENTER+;
           "Grupos MIX: "          +AllTrim(AllToChar(MV_PAR15))+_ENTER+;
           "Tipo Acordo: "         +AllTrim(AllToChar(MV_PAR16))

   aBotoes:={}
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS68Pesq( oLbxAux,_nPosPed,"PEDIDO:")},"Pesquisando..","Aguarde..." )},"","PESQUISAR"               })
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS68NF(   oLbxAux,@oSayAux,@_cMsgTop)},"Pesquisando..","Aguarde..." )},"","MARCACAO por Nota Fiscal"})
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS68PED(  oLbxAux,@oSayAux,@_cMsgTop)},"Pesquisando..","Aguarde..." )},"","MARCACAO por Pedido"     })
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS68PItem(oLbxAux,@oSayAux,@_cMsgTop)},"Pesquisando..","Aguarde..." )},"","MARCACAO por Produto"    })
   aAdd(aBotoes,{"",{|| U_ITMsgLog(_cMsgFil, "FILTROS APLICADOS" )},"","Filtros Aplicados"})

   aSize:=NIL
   _nTotalM:=0
   _cMsgTop:="Total dos itens apurados selciondados: "

   _bCondMarca:={|oLbxAux,nAt| oLbxAux:aArray[nAt][2] }

   _bDblClk := {|| U_MOMS68Click( @oLbxAux, @oSayAux, @_cMsgTop,.F.) }
   _bHeadClk:= {|oLbx, nCol| If(nCol=1,FWMsgRun( ,{|oProc|  U_MOMS68Click( @oLbxAux, @oSayAux, @_cMsgTop, .T.,oProc) } , "Processando... " ),.F.)  }

   While Len(_aProdMarca) > 0 

      If Subs(MV_PAR17,1,2) <> "07"
                         //      ,_aCols     ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc ,_aSizes, _nCampo , bOk  , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk)
         If !U_ITListBox(_cTitulo,aCab,_aProdMarca, .T.    , 2    ,@_cMsgTop,.F.       ,aSize  ,         ,        ,        ,aBotoes ,       ,_bDblClk,          ,_bCondMarca,         ,       ,_bHeadClk)
         
            If U_ITMsg("Confirma SAIR ?",'Atenção!',"Todo processamento será perdido",2,2,2)
               Return .F.
            Else
               Loop
            EndIf
         
         EndIf
      EndIf
      // Cria variaveis M->????? da Enchoice                          
      _aStruct := ZK1->(DBSTRUCT())
      For _nni := 1 to Len(_aStruct)
         wVar := "M->"+ AllTrim(_aStruct[_nni][1])
         &wVar:= CRIAVAR( AllTrim(_aStruct[_nni][1]) ) 
      Next 

      If !Empty(MV_PAR04)
         M->ZK1_CREDES:=MV_PAR04
         M->ZK1_REDES :=AllTrim( Posicione("ACY",1, xFilial("ACY")+MV_PAR04,"ACY_DESCRI"))
      EndIf

      If !Empty(MV_PAR05)
         M->ZK1_CLIENT:=MV_PAR05
         M->ZK1_CLILOJ:=MV_PAR06
         SA1->(DBSetOrder(1))
         If Empty(MV_PAR06) .And. SA1->(DBSeek( xFilial("SA1")+MV_PAR05 ))
            While MV_PAR05 == SA1->A1_COD .And. SA1->A1_MSBLQL = "1".AND. SA1->(!Eof())
               SA1->(DBSkip())
            EndDo
         Else
            SA1->(DBSeek( xFilial("SA1")+MV_PAR05+MV_PAR06 )) 
         EndIf
         If SA1->A1_GRPVEN <> "999999"
            M->ZK1_CREDES:=SA1->A1_GRPVEN
            M->ZK1_REDES :=AllTrim( Posicione("ACY",1, xFilial("ACY")+SA1->A1_GRPVEN,"ACY_DESCRI"))
         EndIf
         M->ZK1_CVENDE:=SA1->A1_VEND
         M->ZK1_VENDER:=Posicione("SA3",1,xFilial("SA3")+SA1->A1_VEND,"A3_NOME")
         M->ZK1_CCOODN:=SA3->A3_SUPER
         M->ZK1_CGEREN:=SA3->A3_GEREN
         M->ZK1_COODNA:=Posicione("SA3",1,xFilial("SA3")+M->ZK1_CCOODN,"A3_NOME")
         M->ZK1_GERENT:=Posicione("SA3",1,xFilial("SA3")+M->ZK1_CGEREN,"A3_NOME")
      EndIf

      If !Empty(MV_PAR09)//VENDEDOR
        M->ZK1_CVENDE:=MV_PAR09
        M->ZK1_VENDER:=Posicione("SA3",1,xFilial("SA3") +MV_PAR09,"A3_NOME")
        M->ZK1_CCOODN:=SA3->A3_SUPER
        M->ZK1_CGEREN:=SA3->A3_GEREN
        M->ZK1_COODNA:=Posicione("SA3",1,xFilial("SA3") +M->ZK1_CCOODN,"A3_NOME")
        M->ZK1_GERENT:=Posicione("SA3",1,xFilial("SA3") +M->ZK1_CGEREN,"A3_NOME")
      EndIf
      If !Empty(MV_PAR08)//COORDENADOR
        M->ZK1_CCOODN:=MV_PAR08
        M->ZK1_COODNA:=Posicione("SA3",1,xFilial("SA3") +MV_PAR08,"A3_NOME")
        M->ZK1_CGEREN:=SA3->A3_GEREN
        M->ZK1_GERENT:=Posicione("SA3",1,xFilial("SA3") +M->ZK1_CGEREN,"A3_NOME")
      EndIf
      If !Empty(MV_PAR07)//GERENTE
         M->ZK1_CGEREN:=MV_PAR07
         M->ZK1_GERENT:=Posicione("SA3",1,xFilial("SA3") +MV_PAR07,"A3_NOME")
      EndIf

      M->ZK1_PERIOD:="Somou Impostos: "+AllTrim(AllToChar(MV_PAR13))+"; Considerou Devolucoes: "+AllTrim(AllToChar(MV_PAR14))+"; Data de "+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02)
      M->ZK1_FORAPU:=LEFT(MV_PAR11,1)//Forma de Apuracao: 1=Sobre Faturamento;2=Sobre Pedido
      M->ZK1_TIPOAC:=LEFT(MV_PAR16,1)//Tipo do Acordo: "1-Aniversario","2-Reforma Reinauguracao","3-Acao Comercial","4-Rebaixa de preco","5-Introducao de produto"
      //If Subs(MV_PAR16,1,1) $ "1|2|3|8"
      M->ZK1_SUBITE:= LEFT(MV_PAR17,2) //StrZero(Val(Subs(MV_PAR17,1,2)),2)
      //EndIf
      M->ZK1_VRAPUR:=0
      M->ZK1_TFATUR:=0
      M->ZK1_TDEVOL:=0

      _aProdutos:={}
      _cTotGeral:=AllTrim(Str(Len(_aProdMarca)))
      nConta:=0
      For P := 1 TO Len(_aProdMarca)
 
         If oproc <> NIL
            nConta++
            oproc:cCaption := ("Lendo Item: "+_aProdMarca[P,_nPosPRD]+" - "+StrZero(nConta,5) +" de "+ _cTotGeral )
            ProcessMessages()
         EndIf
 
         If _aProdMarca[P,1]// *********** LE MARCADOS  ***************
           
            _aProd2Marca[P,1]:=_aProdMarca[P,1]//REPASSA A MARCACAO FEITA PELO O USUARIO PARA A _aProd2Marca
 	                      
            If (nPos:=aScan(_aProdutos,{|I| I[1] == _aProd2Marca[P,_nPosPRD]  })) = 0 .Or. MV_PAR20 = "1" //SE NAO ACHAR O PRODUTO OU SE For PARA SOMAR
               _aProd:={}
               aAdd(_aProd, _aProd2Marca[P,_nPosPRD]    )//01 - Produto           - ZK2_PRODUT 
               aAdd(_aProd, _aProd2Marca[P,_nPosDES]    )//02 - Descrição         - ZK2_DESCRI
               aAdd(_aProd, _aProd2Marca[P,_nPosBMix]    )//03 - Grupo Mix         - ZK2_DESCRI

               aAdd(_aProd, _aProd2Marca[P,_nPosVrApur] )//03 - VALOR APURADO     - ZK2_VRAPUR - VALOR PEDIDOS (VR FAT S/IMP - VR DEV S/IMP) - (VR FAT C/IMP - VR DEV C/ IMP)
               aAdd(_aProd, 0                           )//04 - Valor rateio      - ZK2_RATEIO
               aAdd(_aProd, 0                           )//05 - % Rateio          - ZK2_RATPER
               aAdd(_aProd, 0                           )//06 - Vr Net pedido     - ZK2_NETPED - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
               aAdd(_aProd, 0                           )//07 - Vr Net ajustado   - ZK2_NETAJU - (VR FAT S/ IMP - VR DEV S/ IMP)   /(QTDE FAT 1UM - QTDE DEV 1 UM)
               aAdd(_aProd, _aProd2Marca[P,_nPosQAPU1]  )//08 - Qtde apurada 1UM  - ZK2_QAPU1U - C6_QTDVEN - D2_QUANT  - (D2_QUANT  - D1_QUANT)
               aAdd(_aProd, _aProd2Marca[P,_nPosQAPU2]  )//09 - Qtde apurada 2UM  - ZK2_QAPU2U - C6_UNSVEN - D2_QTSEGUM - (D2_QTSEGUM - D1_QTSEGUM)
               aAdd(_aProd, _aProd2Marca[P,_nPosQPED1U] )//10 - Qtde Ped 1UM      - C6_QTDVEN  - ZK2_QPED1U
               aAdd(_aProd, _aProd2Marca[P,_nPosUNSVEN] )//11 - Qtde. Pedido (2a) - C6_UNSVEN  - ZK2_QPED2U
               aAdd(_aProd, _aProd2Marca[P,_nPosSEGUM]  )//12 - UM (2a)           - C6_SEGUM   - ZK2_UNIDAD
               aAdd(_aProd, _aProd2Marca[P,_nPosVLRIT]  )//13 - Valor pedidos     - C6_VALOR   - ZK2_VRPEDI - RATEIO - SOMA NA CAPA
               aAdd(_aProd, _aProd2Marca[P,_nPosVRCTPE] )//14 - Vlr desc cont ped - C6_I_VLRDC - ZK2_VRCTPE
               aAdd(_aProd, _aProd2Marca[P,_nPosQTDEFA] )//15 - Qtde Faturada 1UM - D2_QUANT   - ZK2_QFAT1U 
               aAdd(_aProd, _aProd2Marca[P,_nPosQFAT1U] )//16 - Qtde Faturada 2UM - D2_QTSEGUM - ZK2_QFAT2U
               aAdd(_aProd, _aProd2Marca[P,_nPosVLRFA]  )//17 - Vr fat s/ imp     - D2_TOTAL   - ZK2_VRFATM - RATEIO - SOMA NA CAPA
               aAdd(_aProd, _aProd2Marca[P,_nPosVRFATI] )//18 - Vr fat c/ imp     - D2_VALBRUT - ZK2_VRFATI
               aAdd(_aProd, _aProd2Marca[P,_nPosVRCTFA] )//19 - Vr contrato fat   - D2_I_VLRDC - ZK2_VRCTFA
               aAdd(_aProd, _aProd2Marca[P,_nPosQDEV1U] )//20 - Qtde Dev 1UM      - D1_QUANT   - ZK2_QDEV1U
               aAdd(_aProd, _aProd2Marca[P,_nPosQDEV2U] )//21 - Qtde Dev 2UM      - D1_QTSEGUM - ZK2_QDEV2U - SOMA NA CAPA
               aAdd(_aProd, _aProd2Marca[P,_nPosVLRDE ] )//22 - Vr Dev s/ imp     - D1_TOTAL   - ZK2_VRDEVM
               aAdd(_aProd, _aProd2Marca[P,_nPosVRDEVI] )//23 - Vr Dev c/ imp     - DEVCOMIMP  - ZK2_VRDEVI
               aAdd(_aProd, _aProd2Marca[P,_nPosVRCTDE] )//24 - Vr contrato dev   - D1_I_VLRDC - ZK2_VRCTDE
               aAdd(_aProd, 0                           )//25 - RECNO DA ZK2 - NA INCLUSAO É ZERADO E NA ALTERACAO É PREENCHIDO

               aAdd(_aProdutos,_aProd)
            Else

               _aProdutos[nPos,n2PosVrApur]+= _aProd2Marca[P,_nPosVrApur]//03 - VALOR APURADO     - ZK2_VRAPUR - VALOR PEDIDOS  - RATEIO - SOMA NA CAPA
               _aProdutos[nPos,n2PosNETPE ]+= _aProd2Marca[P,_nPosNETPE] //06 - Vr Net pedido     - ZK2_NETPED - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
               _aProdutos[nPos,n2PosNETAJ ]+= _aProd2Marca[P,_nPosNETAJ] //07 - Vr Net ajustado   - ZK2_NETAJU - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
               _aProdutos[nPos,n2PosQAPU1 ]+= _aProd2Marca[P,_nPosQAPU1] //08 - Qtde apurada 1UM  - ZK2_QAPU1U - C6_QTDVEN OU D2_QUANT - D1_QUANT
               _aProdutos[nPos,n2PosQAPU2 ]+= _aProd2Marca[P,_nPosQAPU2] //09 - Qtde apurada 2UM  - ZK2_QAPU2U - C6_UNSVEN OU D2_QTSEUM - D1_QTSEGUM
               _aProdutos[nPos,n2PosQ1Ped ]+= _aProd2Marca[P,_nPosQPED1U]//10 - Qtde Ped 1UM      - C6_QTDVEN  - ZK2_QPED1U
               _aProdutos[nPos,n2PosQPed  ]+= _aProd2Marca[P,_nPosUNSVEN]//11 - Qtde. Pedido (2a) - C6_UNSVEN  - ZK2_QPED2U
               _aProdutos[nPos,n2PosVPed  ]+= _aProd2Marca[P,_nPosVLRIT] //13 - Valor pedidos     - C6_VALOR   - ZK2_VRPEDI
               _aProdutos[nPos,n2PosCPed  ]+= _aProd2Marca[P,_nPosVRCTPE]//14 - Vr Contr Pedido   - C6_I_VLRDC - ZK2_VRCTPE - (Valor do desconto contratual do pedido) (Calculo na SELECT (Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC) )
               _aProdutos[nPos,n2PosQ1Fat ]+= _aProd2Marca[P,_nPosQTDEFA]//15 - Qtde Faturada 1UM - D2_QUANT   - ZK2_QFAT1U 
               _aProdutos[nPos,n2PosQ2Fat ]+= _aProd2Marca[P,_nPosQFAT1U]//16 - Qtde Faturada 2UM - D2_QTSEGUM - ZK2_QFAT2U
               _aProdutos[nPos,n2PosVRFAM ]+= _aProd2Marca[P,_nPosVLRFA] //17 - Vr fat s/ imp     - D2_TOTAL   - ZK2_VRFATM - SOMA NA CAPA
               _aProdutos[nPos,n2PosVRFAI ]+= _aProd2Marca[P,_nPosVRFATI]//18 - Vr fat c/ imp     - D2_VALBRUT - ZK2_VRFATI - SOMA NA CAPA
               _aProdutos[nPos,n2PosVRCTFA]+= _aProd2Marca[P,_nPosVRCTFA]//19 - Vr contrato fat   - D2_I_VLRDC - ZK2_VRCTFA
               _aProdutos[nPos,n2PosQDEV1U]+= _aProd2Marca[P,_nPosQDEV1U]//20 - Qtde Dev 1UM      - D1_QUANT   - ZK2_QDEV1U
               _aProdutos[nPos,n2PosQDEV2U]+= _aProd2Marca[P,_nPosQDEV2U]//21 - Qtde Dev 2UM      - D1_QTSEGUM - ZK2_QDEV2U
               _aProdutos[nPos,n2PosVRDEM ]+= _aProd2Marca[P,_nPosVLRDE] //22 - Vr Dev s/ imp     - D1_TOTAL   - ZK2_VRDEVM - SOMA NA CAPA
               _aProdutos[nPos,n2PosVRDEI ]+= _aProd2Marca[P,_nPosVRDEVI]//23 - Vr Dev c/ imp     - DEVCOMIMP  - ZK2_VRDEVI - SOMA NA CAPA
               _aProdutos[nPos,n2PosVRCTDE]+= _aProd2Marca[P,_nPosVRCTDE]//24 - Vr contrato dev   - D1_I_VLRDC - ZK2_VRCTDE

            EndIf
            M->ZK1_VRAPUR+=_aProd2Marca[P,_nPosVrApur]   //03 - VALOR APURADO              - ZK2_VRAPUR - RATEIO - SOMA NA CAPA
            If MV_PAR13 = "1" //COM IMPOSTO 
               M->ZK1_TFATUR+=_aProd2Marca[P,_nPosVRFATI]//18 - Vr fat c/ imp - D2_VALBRUT - ZK2_VRFATI - SOMA NA CAPA
               M->ZK1_TDEVOL+=_aProd2Marca[P,_nPosVRDEVI]//23 - Vr Dev c/ imp - DEVCOMIMP  - ZK2_VRDEVI - SOMA NA CAPA
            Else              //SEM IMPOSTOS
               M->ZK1_TFATUR+=_aProd2Marca[P,_nPosVLRFA] //17 - Vr fat s/ imp - D2_TOTAL   - ZK2_VRFATM - SOMA NA CAPA
               M->ZK1_TDEVOL+=_aProd2Marca[P,_nPosVLRDE] //22 - Vr Dev s/ imp - D1_TOTAL   - ZK2_VRDEVM - SOMA NA CAPA
            EndIf
 
 	      EndIf
      Next

      If Len(_aProdutos) < 1 .And. Subs(MV_PAR16,1,1) == "6"
         U_ITMsg("Não foi selecionado nenhum Pedido.",'Atenção!',"",3)
    	   Loop
      EndIf

      Exit
 
   EndDo


    //   ZK2 - //DEPOIS QUE SOMOU NA INCLUSAO CALCULA OS PREÇO NET POR PRODUTO
    _cTotGeral:=AllTrim(Str(Len(_aProdutos)))
    nConta:=0
    For nPos := 1 TO Len(_aProdutos)
    
        If oproc <> NIL
           nConta++
           oproc:cCaption := ("Calculando Preco NET, Item: "+StrZero(nConta,5) +" de "+ _cTotGeral )
           ProcessMessages()
        EndIf
    
  		  _nVrNetPED:=Round(( _aProdutos[nPos,n2PosVPed]-_aProdutos[nPos,n2PosCPed] )/_aProdutos[nPos,n2PosQ1Ped],3 )// (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO)/C6_QTDVEN // ZK2_NETPED

         If MV_PAR11 = "1"//POR NOTA //Forma de Apuracao: 1=Sobre Faturamento
            _aProdutos[nPos,n2PosNETPE ]:=_nVrNetPED //06 - Vr Net pedido     - ZK2_NETPED - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
            
            _nQtdeApur1um:= _aProdutos[nPos,n2PosQAPU1]//08 - Qtde apurada 1UM  - ZK2_QAPU1U - C6_QTDVEN OU D2_QUANT - D1_QUANT
            _nVrNetAjus  := Round( ( _aProdutos[nPos,n2PosVRFAM]-_aProdutos[nPos,n2PosVRDEM]-(_aProdutos[nPos,n2PosVRCTFA]-_aProdutos[nPos,n2PosVRCTDE]) ) / _nQtdeApur1um ,3) //(VR FAT S/ IMP - VR DEV S/ IMP - D2_I_VLRDC - D1_I_VLRDC) / (QTDE FAT 1UM - QTDE DEV 1 UM)
            _aProdutos[nPos,n2PosNETAJ ]:=_nVrNetAjus //07 - Vr Net ajustado   - ZK2_NETAJU - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
         Else//POR PEDIDO //FORMA DE APURACAO: 2=SOBRE PEDIDO
            _aProdutos[nPos,n2PosNETPE ]:=_nVrNetPED //06 - Vr Net pedido     - ZK2_NETPED - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
            _aProdutos[nPos,n2PosNETAJ ]:=_nVrNetPED //07 - Vr Net ajustado   - ZK2_NETAJU - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
         EndIf
    Next             
    //   ZK2 - //DEPOIS QUE SOMOU NA INCLUSAO CALCULA OS PREÇO NET POR PRODUTO

    _nRec:=0

Else //LER TABELAS GRAVADAS  //// VISUALIZAR (2) / ALTERACAO (4) / EXCLUIR (5) ************************************************************************************

// **********************   LER ZK1 *********************************
    // CRIA VARIAVEIS M->ZK1_????? DA ENCHOICE                          
	DBSelectArea("ZK1")
   _nRec:=Recno()

	For _nni := 1 TO FCount()
		M->&(FieldName(_nni)) := FieldGet(_nni)//ZK1
	Next 

   MV_PAR04:=" "
   MV_PAR05:=" "
   If !Empty(M->ZK1_CLIENT)
	   MV_PAR05:=M->ZK1_CLIENT//PARA O F3 DOS FAVORECIDOS
   ElseIf !Empty(M->ZK1_CREDES)
      MV_PAR04:=LEFT(M->ZK1_CREDES,Len(SA1->A1_GRPVEN))//PARA O F3 DOS FAVORECIDOS
	EndIf

// **********************   LER ZK2 *********************************
	_aProdutos:={}
   ZK2->(DBSetOrder(1))
   ZK2->(DBSeek(xFilial("ZK2")+M->ZK1_CODIGO ))
   
   While xFilial("ZK2")+M->ZK1_CODIGO == ZK2->ZK2_FILIAL+ZK2->ZK2_CODIGO .And. !ZK2->(Eof())

      _aProd:={}
	   If ZK2->ZK2_TIPREG = "I"// ITENS ACUMULADOS
         For Z2 := 1 TO Len(aCposZK2)      
             If aCposZK2[Z2,1] = "ZK2_BMIX" 
                If "GRUPO G" $ ZK2->ZK2_PRODUT 
                  _lMix := .T.
                  aAdd(_aProd ,Subs(ZK2->ZK2_PRODUT,7,2 ))
                Else
                  aAdd(_aProd ,Posicione("SB1",1,xFilial ("SB1")+ZK2->ZK2_PRODUT ,"B1_I_BIMIX")) //             
                EndIf
             ElseIf (nPos:=aScan(aCposZK2,{|C| C[2] = (Len(_aProd)+1) })) <> 0//PROCURA A POSICAO (nPos) DO TAMANHO DA _aProd (Len(_aProd)+1) NO ARRARY DA aCposZK2
                aAdd(_aProd,ZK2->( FieldGet( FieldPos( aCposZK2[nPos,1] ) ) ))
             Else 
                aAdd(_aProd,"")
             EndIf
         Next
         
         aAdd(_aProd, ZK2->(RECNO()) )//25 - RECNO DA ZK2 - NA INCLUSAO É ZERADO E NA ALTERACAO É PREENCHIDO
         
         aAdd(_aProdutos,_aProd)

	   ElseIf ZK2->ZK2_TIPREG = "P" .And. ZK2->ZK2_DESCRI = "PROVISAO"// PEDIDOS COM ITENS
         //LER DIRETO DA TABELA ZK2 NA HORA DE MOSTRAR NA ALTERACAO
         aAdd(_aProd,.T.)//TUDO MARCADO
         aAdd(_aProd,.T.)//TUDO MARCADO
         For Z2 := 3 TO Len(aCab)
             If (nPos:=aScan(aCposPOZK2,{|C| C[2] = Z2 })) <> 0//PROCURA A POSICAO (nPos) DO TAMANHO DA _aProd (Len(_aProd)+1) NO ARRARY DA aCposPOZK2
                aAdd(_aProd,ZK2->( FieldGet( FieldPos( aCposPOZK2[nPos,1] ) ) ))
             Else 
                aAdd(_aProd,"")
             EndIf
         Next
         
         aAdd(_aProd, ZK2->(RECNO()) )//25 - RECNO DA ZK2 - NA INCLUSAO É ZERADO E NA ALTERACAO É PREENCHIDO
         
         aAdd(_aProd2Marca,_aProd)

      EndIf
      If ZK2->ZK2_DESCRI = "PROVISAO"
         MV_PAR19:="1"         
      EndIf

      ZK2->(DBSkip())
   EndDo

// **********************   LER ZK3 *********************************
	aCols  :={}
   
   ZK3->(DBSetOrder(1))
   ZK3->(DBSeek(xFilial("ZK3")+M->ZK1_CODIGO ))
   
   While xFilial("ZK3")+M->ZK1_CODIGO == ZK3->ZK3_FILIAL+ZK3->ZK3_CODIGO .And. !ZK3->(Eof())
      _aProd:={}

      aAdd(_aProd,ZK3->ZK3_CONTRA)//01
      aAdd(_aProd,ZK3->ZK3_PARCEL)//02 *
      aAdd(_aProd,ZK3->ZK3_VALOR )//03
      aAdd(_aProd,ZK3->ZK3_VENCTO)//04 *
      aAdd(_aProd,ZK3->ZK3_TITULO)//05      
      aAdd(_aProd,ZK3->ZK3_TITPAR)//06
      aAdd(_aProd,ZK3->ZK3_FAVORE)//07
      aAdd(_aProd,ZK3->ZK3_FAVLOJ)//08
      aAdd(_aProd,ZK3->ZK3_FAVDES)//09
      aAdd(_aProd,ZK3->(RECNO()) )//10
      aAdd(_aProd,.F. )//11

      aAdd(aCols,_aProd)

      ZK3->(DBSkip())
   EndDo
// **********************   LEU ZK3 *********************************
   aCols:=aSort(aCols,,,{|x, y| DToS(x[4])+x[2] < DToS(y[4])+y[2]})
   

EndIf// *************************************************************** FIM DAS LEITURAS DO INCLUIR / ALTERAR / VISULIZAR / EXCLUIR ***************************

If Subs(MV_PAR17,1,2) <> "07"
   If Len(_aProdutos) = 0 .And. _nOpc <> 5 .And. _nOpc <> 2 .And. !(Subs(M->ZK1_TIPOAC,1,1) $ "7|9") // <> (EXCLUI) e <> (VISUALIZAR)
      U_ITMsg("Não Tem Registros para alterar.",'Atenção!',"Utilize a opcao EXCLUIR para para eliminar esse Acordo incorreto.",3) 
      Return .T.
   EndIf
EndIf
//   ZK2 - //DEPOIS QUE SOMOU NA INCLUSAO E LEU NA ALTERACAO TRANSFORMA EM CARACTER OS NUMERICOS
_cTotGeral:=AllTrim(Str(Len(_aProdutos)))
nConta:=0
For nPos := 1 TO Len(_aProdutos)

    If oproc <> NIL
       nConta++
       oproc:cCaption := ("Ajustando campos numericos, Item: "+StrZero(nConta,5) +" de "+ _cTotGeral )
       ProcessMessages()
    EndIf

    _aProdutos[nPos,n2PosVrApur]:= TRANS(_aProdutos[nPos,n2PosVrApur],_cPictVALOR) //03 - VALOR APURADO     - ZK2_VRAPUR - VALOR PEDIDOS 
    _aProdutos[nPos,n2PosVrRa  ]:= TRANS(_aProdutos[nPos,n2PosVrRa  ],_cPictVALOR) //04 - Valor rateio      - ZK2_RATEIO - Calculado via tela
    _aProdutos[nPos,n2PosPeRa  ]:= TRANS(_aProdutos[nPos,n2PosPeRa  ],_cPictVALOR) //05 - % Rateio          - ZK2_RATPER - Calculado via tela
    _aProdutos[nPos,n2PosNETPE ]:= TRANS(_aProdutos[nPos,n2PosNETPE ],_cPictVLNET) //06 - Vr Net pedido     - ZK2_NETPED - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
    _aProdutos[nPos,n2PosNETAJ ]:= TRANS(_aProdutos[nPos,n2PosNETAJ ],_cPictVLNET) //07 - Vr Net ajustado   - ZK2_NETAJU - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
    _aProdutos[nPos,n2PosQAPU1 ]:= TRANS(_aProdutos[nPos,n2PosQAPU1 ],_cPictQTDE ) //08 - Qtde apurada 1UM  - ZK2_QAPU1U - C6_QTDVEN 
    _aProdutos[nPos,n2PosQAPU2 ]:= TRANS(_aProdutos[nPos,n2PosQAPU2 ],_cPictQTDE ) //09 - Qtde apurada 2UM  - ZK2_QAPU2U - C6_UNSVEN 
    _aProdutos[nPos,n2PosQ1Ped ]:= TRANS(_aProdutos[nPos,n2PosQ1Ped ],_cPictQTDE ) //10 - Qtde Ped 1UM      - ZK2_QPED1U - C6_QTDVEN 
    _aProdutos[nPos,n2PosQPed  ]:= TRANS(_aProdutos[nPos,n2PosQPed  ],_cPictQTDE ) //11 - Qtde. Pedido (2a) - ZK2_QPED2U - C6_UNSVEN 
    _aProdutos[nPos,n2PosVPed  ]:= TRANS(_aProdutos[nPos,n2PosVPed  ],_cPictVALOR) //13 - Valor pedidos     - ZK2_VRPEDI - C6_VALOR   - RATEIO - SOMA NA CAPA
    _aProdutos[nPos,n2PosCPed  ]:= TRANS(_aProdutos[nPos,n2PosCPed  ],_cPictVALOR) //14 - Vr Contr Pedido   - ZK2_VRCTPE - C6_I_VLRDC - (Valor do desconto contratual do pedido) (Calculo na SELECT (Round(((C6_VALOR * C6_I_PDESC)/100),2) C6_I_VLRDC) )
    _aProdutos[nPos,n2PosQ1Fat ]:= TRANS(_aProdutos[nPos,n2PosQ1Fat ],_cPictQTDE ) //15 - Qtde Faturada 1UM - ZK2_QFAT1U - D2_QUANT   
    _aProdutos[nPos,n2PosQ2Fat ]:= TRANS(_aProdutos[nPos,n2PosQ2Fat ],_cPictQTDE ) //16 - Qtde Faturada 2UM - ZK2_QFAT2U - D2_QTSEGUM
    _aProdutos[nPos,n2PosVRFAM ]:= TRANS(_aProdutos[nPos,n2PosVRFAM ],_cPictVALOR) //17 - Vr fat s/ imp     - ZK2_VRFATM - D2_TOTAL   - RATEIO - SOMA NA CAPA
    _aProdutos[nPos,n2PosVRFAI ]:= TRANS(_aProdutos[nPos,n2PosVRFAI ],_cPictVALOR) //18 - Vr fat c/ imp     - ZK2_VRFATI - D2_VALBRUT
    _aProdutos[nPos,n2PosVRCTFA]:= TRANS(_aProdutos[nPos,n2PosVRCTFA],_cPictVALOR) //19 - Vr contrato fat   - ZK2_VRCTFA - D2_I_VLRDC
    _aProdutos[nPos,n2PosQDEV1U]:= TRANS(_aProdutos[nPos,n2PosQDEV1U],_cPictQTDE ) //20 - Qtde Dev 1UM      - ZK2_QDEV1U - D1_QUANT  
    _aProdutos[nPos,n2PosQDEV2U]:= TRANS(_aProdutos[nPos,n2PosQDEV2U],_cPictQTDE ) //21 - Qtde Dev 2UM      - ZK2_QDEV2U - D1_QTSEGUM
    _aProdutos[nPos,n2PosVRDEM ]:= TRANS(_aProdutos[nPos,n2PosVRDEM ],_cPictVALOR) //22 - Vr Dev s/ imp     - ZK2_VRDEVM - D1_TOTAL   - SOMA NA CAPA
    _aProdutos[nPos,n2PosVRDEI ]:= TRANS(_aProdutos[nPos,n2PosVRDEI ],_cPictVALOR) //23 - Vr Dev c/ imp     - ZK2_VRDEVI - DEVCOMIMP 
    _aProdutos[nPos,n2PosVRCTDE]:= TRANS(_aProdutos[nPos,n2PosVRCTDE],_cPictVALOR) //24 - Vr contrato dev   - ZK2_VRCTDE - D1_I_VLRDC

Next             
//   ZK2 - //DEPOIS QUE SOMOU NA INCLUSAO E LEU NA ALTERACAO TRANSFORMA EM CARACTER OS NUMERICOS

If Len(_aProdutos) > 0 .Or. _nOpc <> 5  .Or. _nOpc <> 2 // <> (EXCLUI) e <> (VISUALIZAR)
   nOpc:=_nOpc
   Private aHeader:={}//   ZK3
   aAdd(aHeader,{"Contrato"  ,"ZK3_CONTRA","999999999"            ,09,0,"","","C","","","","",".T."})//01 
   _nPosCon:=Len(aHeader)
   aAdd(aHeader,{"Parcela"   ,"ZK3_PARCEL","99"                   ,02,0,"","","C","","","","",".T."})//02
   _nPosPar:=Len(aHeader)
   aAdd(aHeader,{"Valor"     ,"ZK3_VALOR" ,"@E 999,999,999,999.99",15,2,"","","N","","","","",".T."})//03
   _nPosPVlr:=Len(aHeader)
   aAdd(aHeader,{"Vencimento","ZK3_VENCTO","@D"                   ,08,0,"","","D","","","","",".T."})//04
   _nPosVen:=Len(aHeader)
   aAdd(aHeader,{"NCC"       ,"ZK3_TITULO","@!"                   ,09,0,"","","C","","","","","If(nOpc=3,.T.,.F.)"})//05
   aAdd(aHeader,{"Parcela"   ,"ZK3_TITPAR","99"                   ,02,0,"","","C","","","","","If(nOpc=3,.T.,.F.)"})//06

   aAdd(aHeader,{"Cod Favorec."   ,"ZK3_FAVORE","@!"                    ,06,0,"U_MEST21Val()","","C","","","","",".T."})//07 
   _nPosFavorec:=Len(aHeader)
   aAdd(aHeader,{"Loja Favorec."  ,"ZK3_FAVLOJ","@!"                    ,04,0,"","","C","","","","",".T."})//08 
   _nPosLojaFav:=Len(aHeader)
   aAdd(aHeader,{"Nome"           ,"ZK3_FAVDES","@!"                    ,50,0,"","","C","","","","",".F."})//09 
   _nPosNomFav:=Len(aHeader)
   // pega tamanhos das telas
   _aSize := MsAdvSize()
   _aInfo := { _aSize[1] , _aSize[2] , _aSize[3] , _aSize[4] , 1 , 1 }
   
   aObjects := {}
   aAdd( aObjects, { 100 , 100 , .T. , .T. } )
   aAdd( aObjects, { 100 , 100 , .T. , .T. } )
   aAdd( aObjects, { 100 , 100 , .T. , .T. } )
   
   aPosObj := MsObjSize( _aInfo , aObjects )

   nGDAction:= IIf( _nOpc <> 3 .And. _nOpc <> 4 .And. _nOpc <> 6  , 0 , GD_INSERT + GD_UPDATE + GD_DELETE )

   aGets:={}
   aTela:={}
   _bEfetivar :={|| (_lGrava:=.T.,oDlg2:End()) }
   _bSair     :={|| (_lGrava:=.F.,oDlg2:End()) }

   aBotoes:={}
   If Len(_aProdutos) > 0
      aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS68PPV(_oListProd,"S") },"Lendo Pedido.." ,"Aguarde...")},"","Ver Pedidos"   })
   EndIf
   
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| U_MOMS68EM(.F.,oMsMGet:aCols,.T.) },"Lendo Dados.." ,"Aguarde...")},"","Reenvia Email"   })

   If Len(_aProdutos) > 0
      //__cVendedor := aCols[nLin][1]          M->ZK1_CLIENT:=MV_PAR05
      M->ZK1_CLILOJ:=MV_PAR06

      aAdd(aBotoes,{"",{|| U_MOMS68NT(1)  },"","Compensação"   })
   EndIf
   
   If _nOpc = 4 .Or. _nOpc = 3
      aAdd(aBotoes,{"",{|| MOMS068D(oMsMGet)  },"","Gerar parcelas por Contrato"   })
   EndIf

   While .T.// ***************************  TELA PRINCIPAL *****************************************

      _lGrava:=.F.
      aGets:={}
      aTela:={}

      If Len(_aProdutos) > 0
         _nAlt := 0
      Else
         _nAlt := 89
      EndIf

      _nLinGEt:=aPosObj[1][03]-32 + _nAlt
      _nColGEt:=aPosObj[1][04]-1

      DEFINE MSDIALOG oDlg2 TITLE _cTitulo OF oMainWnd PIXEL FROM _aSize[7],0 TO _aSize[6],_aSize[5]

         ///***********************  MSMGET() ************************* ZK1
                                                                                            //Largura , ALTURA
            oPnlTop := TPanel():New( aPosObj[1][01] , aPosObj[1][02] , , oDlg2 , , , , , , aPosObj[1][04] , aPosObj[1][03]+_nAlt , .F. , .F. )


            //MsmGet(): New (   [ c Alias], uPar2,nOpc>,,,, [ aAcho], [ aPos]               ,[ aCpos],nModelo, [ uPar11], [ uPar12], [ uPar13], [ oWnd], [ lF3], [ lMemoria], [ lColumn], [ caTela], [ lNoFolder], [ lProperty], [ aField], [ aFolder], [ lCreate], [ lNoMDIStretch], [ uPar25],lOrderACho, lUnqFocus)
            oEnCh1:=MsMget():New( "ZK1" ,_nRec ,_nOpc,,,,         ,{1,1,_nLinGEt,_nColGEt},        ,       ,          ,          ,           , oPnlTop,  )  


         ///***********************  LISTBOX ************************* ZK2
         //Ordena o Array pela Descrição
         If Len(_aProdutos) > 0
           If !_lMix
               _aProdutos:=aSort(_aProdutos,,,{|x, y| x[2] < y[2]})
           EndIf
           @aPosObj[2][01] , aPosObj[2][02]	LISTBOX	_oListProd	FIELDS	HEADER ""	; //ON		DblClick( EVAL({|| MOMS68Edit( _oListProd,_nOpc ) }) )	;
           							SIZE	aPosObj[2][04] , ( aPosObj[2][03] - aPosObj[2][01] ) OF oDlg2 PIXEL

           _oListProd:AHeaders  := aClone( aCab2 )
           _oListProd:SetArray( _aProdutos )
           //_oListProd:bKeyPres = { | nKey, nFlags | KeyCharoLbx( _oListProd, nKey, nFlags,oDlg2)}
           
           _oListProd:bLDblClick := {||MOMS068ET(_aProdutos,_oListProd,4/*n2PosVrRa*/,oEnCh1) }  
           _cMacro:=""
           For P := 1 TO Len(aCab2)
           	   _cMacro +=  IIf(P == 1 , "{|| { ", ",") + "_aProdutos[_oListProd:nAt,"+cValtoChar(P)+"]" + IIf(P == Len(aCab2), "} }", "")
           Next   
           _bLine := &(_cMacro)
           _oListProd:bLine     := _bLine
         EndIf

         ///***********************  MSNEWGETDADOS() ************************* ZK3
                                 //[ nTop]          , [ nLeft]   , [ nBottom] , [ nRight ] , [ nStyle],cLinhaOk,cTudoOk,cIniCpos, [ aAlter], [ nFreeze], [ nMax], [ cFieldOk], [ cSuperDel], [ cDelOk], [ oWnd], [ aPartHeader], [ aParCols], [ uChange], [ cTela], [ aColsSize] 
         oMsMGet := MsNewGetDados():New((aPosObj[3,1]),aPosObj[3,2],aPosObj[3,3],aPosObj[3,4],nGDAction ,        ,       ,        ,          ,           ,        ,            ,             ,          ,oDlg2   ,aHeader        , aCols     ,)
	   
         oDlg2:lMaximized:=.T.

      	M->ZK1_NSUBIT := Tabela("ZL", M->ZK1_SUBITE, .F.)

      ACTIVATE MSDIALOG oDlg2 ON INIT (EnchoiceBar(oDlg2,_bEfetivar,_bSair,,aBotoes) )//,;//oPnlTop:Align := CONTROL_ALIGN_TOP,;oMsMGet:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT )
      
      If _lGrava 
         //oMsMGet:aCols : os daddos alterados na tela só existe nesse objeto que ainda existe mesmo apos fechar a tela
         
         FWMsgRun( ,{|oproc| _lGrava := MOMS68Grv(oMsMGet:aCols,oproc,_nOpc)} , "Gravando Dados.." , "Aguarde..." ) 
	      
         If !_lGrava
            aCols:=oMsMGet:aCols
            Loop
         EndIf   
      
         If _nOpc = 6
            _lRetorno:=.T.
            If U_ITMsg("Confirma a Efetivacao ?",'Atenção!',,3,2,3,,"CONFIRMA","SAIR")      
               FWMsgRun(,{|oproc|  _lRetorno:=MGeraNCC(oproc)   },"Aguarde...","Gerando NCC...")
               If _lRetorno
                  U_ITMsg("EFETIVACAO GRAVADA COM SUCESSO","Atenção",,2)
               EndIf
               
               If Subs(M->ZK1_SUBITE ,1,2) <> "07"
                  cCordenador := Posicione("SA3",1,xFilial("SA3") +M->ZK1_CVENDE,"A3_SUPER")
                  cNomeCoord := Posicione("SA3",1,xFilial("SA3") +cCordenador,"A3_NOME")
                  cEmail := Posicione("SA3",1,xFilial("SA3") +cCordenador,"A3_EMAIL")
                  U_MOMS068F(M->ZK1_CODIGO,oMsMGet,Posicione("SA1",1,xFilial("SA1")+M->ZK1_FAVORE+M->ZK1_FAVLOJ,"A1_NOME"),cNomeCoord,cEmail)
               EndIf
            EndIf
         EndIf

      ElseIf (_nOpc = 3 .Or. _nOpc = 4) .And. !U_ITMsg("Confirma SAIR ?",'Atenção!',"Todas as alterações serão perdidas!",3,2,2)
         aCols:=oMsMGet:aCols
         Loop   
      EndIf
   
      Exit

   EndDo

EndIf



Return _lGrava 

/*
===============================================================================================================================
Programa----------: MOMS68Click
Autor-------------: Alex Wallauer
Data da Criacao---: 06/10/2022
===============================================================================================================================
Descrição---------: Rotina de gravação do Array
===============================================================================================================================
Parametros--------: oLbxDados = Objeto Lisbox 
------------------: oSayAux   = Objeto Say da Mensagem
------------------: _cMsgTop  = Mesnsagem exibida em cima do Listbox 
------------------: lHeader   = Define se foi executado no Clique na primeira coluna
------------------: oProc     = Status de Processamento
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/  
User Function MOMS68Click( oLbxDados As Object, oSayAux As Object, _cMsgTop As Char, lHeader As Logical, oProc As Object) As Logical
Local _nPos     := oLbxDados:nAt As Numeric
Local _lMarcaPos:= oLbxDados:aArray[ _nPos , 01 ] As Logical //MARCAÇÃO da POSICAO ATUAL 
Local _nTam     := 0 As Numeric
Local _nCol     := _nPosVrApur As Numeric
Default lHeader := .F. 

   If lHeader
      If _nTotalM <> 0 .And. !oLbxDados:aArray[ _nPos , 2 ]//Se bolinha Verde da segunda coluna somente
         U_ITMsg("Posicione o cursor em uma linha marcada com a bolinha VERDE para desmarcar todos","Atenção",,3)
      EndIf

      _nTam := Len( oLbxDados:aArray )
      oproc:cCaption := ("Atualizando os registros... Total: "+AllTrim(Str(_nTam)))
      ProcessMessages()
      _nTotalM:=0
      For _nPos := 1 To _nTam
          
            If !oLbxDados:aArray[ _nPos , 02 ] //Se bolinha vermelha na segunda coluna ignora
               Loop
            EndIf

            oLbxDados:aArray[ _nPos , 01 ] := !_lMarcaPos//oLbxDados:aArray[ _nPos , 01 ] //TIREI A INVERSÃO GERAL

            If oLbxDados:aArray[ _nPos , 01 ]
               _nTotalM += Val(StrTran(StrTran(oLbxDados:aArray[_nPos][_nCol],".",""),",","."))
            //Else
            // _nTotalM -= Val(StrTran(StrTran(oLbxDados:aArray[_nPos][_nCol],".",""),",","."))
            EndIf
            
      Next _nPos
   
   Else//If oLbxDados:aArray[ _nPos , 02 ] //Se bolinha Verde   

      oLbxDados:aArray[ _nPos , 01 ] := !oLbxDados:aArray[ _nPos , 01 ]

      If oLbxDados:aArray[ _nPos , 01 ]
         _nTotalM += Val(StrTran(StrTran(oLbxDados:aArray[_nPos][_nCol],".",""),",","."))
      Else
         _nTotalM -= Val(StrTran(StrTran(oLbxDados:aArray[_nPos][_nCol],".",""),",","."))
      EndIf

   EndIf

   _cMsgTop :=  "Total dos itens apurados selciondados: "+ AllTrim(Transform(  _nTotalM  , _cPictTOTAL ))
   oSayAux:Refresh()
   oLbxDados:Refresh()

Return

/*===============================================================================================================================
Programa----------: MOMS68Grv
Autor-------------: Alex Wallauer
Data da Criacao---: 12/08/2022
===============================================================================================================================
Descrição---------: GRAVACAO DOS DADOS
===============================================================================================================================
Parametros--------: aCols,oproc,_nOpcx
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================*/
Static Function MOMS68Grv(aCols As Array, oproc As Object, _nOpcx As Numeric) As Logical
Local nConIten As Numeric, nConCmp As Numeric
Local aProd := {} As Array
Z19->(DBSetOrder(1))
ZK3->(DBSetOrder(1))

If _nOpcx = 2//VISUALIZAR
   Return .T.
ElseIf _nOpcx = 5//EXCLUIR

   If !U_ITMsg("Confirma EXCLUSAO ?",'Atenção!',,2,2,2)
      Return .F.
   EndIf

   BEGIN TRANSACTION
   
   ZK1->(RecLock("ZK1",.F.))
   ZK1->(DBDELETE())

   While ZK2->(DBSeek(xFilial("ZK2")+M->ZK1_CODIGO )) .And. !ZK2->(Eof())
	   ZK2->(RecLock("ZK2",.F.))
	   ZK2->(DBDELETE())
	EndDo

   While ZK3->(DBSeek(xFilial("ZK3")+M->ZK1_CODIGO )) .And. !ZK3->(Eof())
	   ZK3->(RecLock("ZK3",.F.))
	   ZK3->(DBDELETE())
	EndDo

   END TRANSACTION
   
   U_ITMsg("DADOS EXCUIDOS COM SUCESSO","Atenção",,2)
   
   Return .T.
EndIf

//******************** INCLUSAO E ALTERAÇÕES ********************
If !Obrigatorio(aGets,aTela)
   Return .F.
EndIf
nValorAcordo:=0
lTemDataVancidas:=.F.
lTudoOK:=.T.
ZK3->( DBSetOrder(2) )//ZK3_FILIAL+ZK3_CONTRA
For nConIten := 1 to Len(aCols)
	
   If aCols[nConIten][Len(aCols[nConIten])]//DELETADOS
      Loop
   EndIf	    
   
   _lTodosPreenchidos:=.F.
   If !Empty(aCols[nConIten][1]) .AND.;//ZK3_CONTRA
      !Empty(aCols[nConIten][3]) .AND.;//ZK3_VALOR
      !Empty(aCols[nConIten][4]) .AND.;//ZK3_VENCTO
      !Empty(aCols[nConIten][7]) .AND.;//ZK3_FAVORE
      !Empty(aCols[nConIten][8])       //ZK3_FAVLOJ
      _lTodosPreenchidos:=.T.
   EndIf

   If Len(aCols) > 1

      If _lTodosPreenchidos
            
         If aScan(aProd,aCols[nConIten][1]+aCols[nConIten][2]) = 0 // ZK3_CONTRA + ZK3_PARCEL
            aAdd(aProd,aCols[nConIten][1]+aCols[nConIten][2])
         Else   
            lTudoOK:=.F.
            U_ITMsg("Contrato + Parcela: "+aCols[nConIten][1]+aCols[nConIten][2]+" Repetidos.","Atenção",;
                     "Apague ou Altere o Contrato + Parcela da linha: "+AllTrim(Str(nConIten)),1)
            Exit
         EndIf   
            
      Else
         lTudoOK:=.F.
         U_ITMsg("É necessário informar Contrato + Valor + Vencimento da NCC antes da gravação.","Atenção",;
                  "Insira produtos validos, não repetidos e preencha todos os campos obrigatorios da linha",1)
         Exit
      EndIf    
   Else
      If !_lTodosPreenchidos
         lTudoOK:=.F.
         U_ITMsg("É necessário informar Contrato + Valor + Vencimento + FavoreciDDo da NCC antes da gravação.","Atenção",;
                  "Insira produtos validos, não repetidos e preencha todos os campos obrigatorios da linha",1)
         Exit
      EndIf    
   EndIf 
   
   nValorAcordo+=aCols[nConIten][3]

   If aCols[nConIten][4] < Date()
      lTemDataVancidas:=.T.
   EndIf

   If ZK3->(DBSeek(xFilial("ZK3")+aCols[nConIten][1]+aCols[nConIten][2])) //ZK3_FILIAL+ZK3_CONTRA
      While xFilial("ZK3")+aCols[nConIten][1] = ZK3->(ZK3_FILIAL+ZK3_CONTRA) .And. ZK3->(!Eof())
         If ZK3->ZK3_CODIGO <> M->ZK1_CODIGO
            U_ITMsg("Numero do contrato: "+aCols[nConIten][1]+" já pertence ao acordo: "+ZK3->ZK3_CODIGO,"Atenção",,3)
            
            Return .F.//Exit

         EndIf
         ZK3->(DBSkip())
      EndDo

   EndIf

Next

ZK3->( DBSetOrder(1) )

If !lTudoOK
	Return .F.
EndIf

If nValorAcordo  = 0
   U_ITMsg("A somatoria dos Valores das parcelas esta zerada.","Atenção",;
           "É obrigatorio o lançamento de parcelas.",1)
	Return .F.
EndIf

If nValorAcordo <> M->ZK1_VLRCOR
   If Subs(MV_PAR19,1,1) = "2"// Provisão = Nao
      U_ITMsg("A somatoria dos Valores das parcelas "+cValtochar(nValorAcordo)+" é diferente do Valor do Acordo : "+cValtochar(M->ZK1_VLRCOR),"Atenção",;
              "A somatoria das parcelas tem que ser igual ao valor do Acordo.",1)
	   Return .F.
   Else// Provisão = SIM
      If !U_ITMsg("A somatoria dos Valores das parcelas "+cValtochar(nValorAcordo)+" é diferente do Valor total da Provisao : "+cValtochar(M->ZK1_VLRCOR),"Atenção",;
                  "Deseja atualizar o valor total da Provisao ? ",2,2,3,,"ATUALIZAR","VOLTAR")
	      Return .F.
      Else
         M->ZK1_VLRCOR := nValorAcordo
         If Len(_aProdutos) > 0
            _aProdutos[1,n2PosVrRa  ]:= TRANS(nValorAcordo     ,_cPictVALOR)//04 - Valor rateio      - ZK2_RATEIO - Calculado via tela
            _aProdutos[1,n2PosNETAJ ]:= TRANS((nValorAcordo*-1),_cPictVALOR)//07 - Vr Net ajustado   - ZK2_NETAJU - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
         EndIf
         If Len(_aProd2Marca) > 0
            _aProd2Marca[1,_nPosVLRat ]:= nValorAcordo     //04 - Valor rateio      - ZK2_RATEIO - Calculado via tela
            _aProd2Marca[1,_nPosNETAJ ]:= (nValorAcordo*-1)//07 - Vr Net ajustado   - ZK2_NETAJU - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
         EndIf
      EndIf
   EndIf
EndIf

If lTemDataVancidas
   If U_ITMsg("Existem datas de Vencimento de parcelas Vencidas. Deseja Corrigir? ","Atenção",,3,2,2)
	   Return .F.
   EndIf
EndIf

If !U_ITMsg("Confirma GRAVACAO ?",'Atenção!',,2,2,2)
   Return .F.
EndIf

BEGIN TRANSACTION

///****************** ZK1 ************************************ CAPA
ZK1->( DBSetOrder(1) )
ZK1->(RecLock("ZK1", !ZK1->(DBSeek(xFilial("ZK1")+M->ZK1_CODIGO)) ))
AVREPLACE("M","ZK1")//GRAVA TODOS OS CAMPOS M->ZK1_????? NO ZK1->ZK1_?????
ZK1->ZK1_FILIAL:= xFilial("ZK1")
ZK1->ZK1_STATUS:= IIf(Subs(MV_PAR19,1,1)=="1","5","1")
ZK1->(MSUnLock())
ConfirmSx8() 

///****************** ZK2 ************************************ ITENS
For nConIten := 1 to Len(_aProdutos)
	
	If _aProdutos[nConIten][Len(_aProdutos[nConIten])] <> 0// ALTERACAO
      ZK2->(DBGoTo( _aProdutos[nConIten][Len(_aProdutos[nConIten])] ))
	   ZK2->(RecLock("ZK2",.F.))
	Else// INLCLUSAO
	   ZK2->(RecLock("ZK2",.T.))
	   ZK2->ZK2_TIPREG := "I"//**** ITENS (PRODUTOS ACUMULADOS DOS PEDIDOS) *******
      ZK2->ZK2_FILIAL := xFilial("ZK2")
	   ZK2->ZK2_CODIGO := M->ZK1_CODIGO
      ZK2->ZK2_TIPOAC := M->ZK1_TIPOAC
	EndIf   
	
   For nConCmp := 1 to Len(aCposZK2)
       If aCposZK2[nConCmp,3] //SE NUMERICO
          ZK2->(FieldPut(FieldPos(aCposZK2[nConCmp,1]), Val(  StrTran(StrTran(_aProdutos[ nConIten, aCposZK2[nConCmp,2] ],".",""),",",".") ) ))
       Else//Se não é numerico
		    ZK2->(FieldPut(FieldPos(aCposZK2[nConCmp,1]), _aProdutos[nConIten, aCposZK2[nConCmp,2] ]))
       EndIf  
	Next 
   ZK2->(MSUnLock())

Next 

//********************  PEDIDOS *********************************
SC5->( DBSetOrder(1) )

If _nOpcx = 3 .And. (Subs(MV_PAR20,1,1) == "1" .Or. Subs(MV_PAR19,1,1) == "1")
   _aProd2Marca := {}
EndIf

For nConIten := 1 to Len(_aProd2Marca)

   If _aProd2Marca[nConIten,1]// *********** LE MARCADOS  ***************
      _nColRecno:=Len(_aProd2Marca[nConIten])
	   If _aProd2Marca[nConIten][ _nColRecno ] <> 0// ALTERACAO
         ZK2->(DBGoTo( _aProd2Marca[nConIten][ _nColRecno ] ))
	      ZK2->(RecLock("ZK2",.F.))
	   Else// INLCLUSAO
	      ZK2->(RecLock("ZK2",.T.))
	      ZK2->ZK2_TIPREG := "P"//******  PEDIDOS COM TODOS OS PRODUTOS ******
         ZK2->ZK2_FILIAL := xFilial("ZK2")
	      ZK2->ZK2_CODIGO := M->ZK1_CODIGO		
         ZK2->ZK2_TIPOAC := M->ZK1_TIPOAC
	      ZK2->ZK2_NOTA   := LEFT(  _aProd2Marca[nConIten, _nPosNF ], Len(ZK2->ZK2_NOTA)   )//NF
	      ZK2->ZK2_SERIE  := SubStr(_aProd2Marca[nConIten, _nPosNF ], Len(ZK2->ZK2_NOTA)+2 )//SERIE
         If SC5->( DBSeek( _aProd2Marca[nConIten,_nPosFil]+_aProd2Marca[nConIten,_nPosPed] ) ) 
	         ZK2->ZK2_VEND1  := SC5->C5_VEND1
	         ZK2->ZK2_VEND2  := SC5->C5_VEND2
	         ZK2->ZK2_VEND3  := SC5->C5_VEND3
	         ZK2->ZK2_VEND4  := SC5->C5_VEND4
	         ZK2->ZK2_VEND5  := SC5->C5_VEND5
         EndIf
      EndIf	   
      For nConCmp := 1 to Len(aCposPOZK2)
       //If aCposPOZK2[nConCmp,3] //SE NUMERICO
		 //   ZK2->(FieldPut(FieldPos(aCposPOZK2[nConCmp,1]), Val(  StrTran(StrTran(_aProd2Marca[nConIten, aCposPOZK2[nConCmp,2] ],".",""),",",".") ) ))
       //Else//Se não é numerico
            _nPos1:=aCposPOZK2[nConCmp,2] 
            _nCpo1:=aCposPOZK2[nConCmp,1]
	         ZK2->(FieldPut(FieldPos(aCposPOZK2[nConCmp,1]), _aProd2Marca[nConIten, aCposPOZK2[nConCmp,2] ]))
       //EndIf
	   Next 
   
      ZK2->(MSUnLock())

	EndIf   

Next 

///****************** GRAVACAO DO ZK3 SEMPRE ************************************
ZK3->( DBSetOrder(1) )
While ZK3->(DBSeek(xFilial("ZK3")+M->ZK1_CODIGO )) .And. !ZK3->(Eof())
   ZK3->(RecLock("ZK3",.F.))
   ZK3->(DBDELETE())
   ZK3->(DBSkip())
EndDo

For nConIten := 1 to Len(aCols)
	
	If !aCols[nConIten][Len(aCols[nConIten])]//DELETADOS

	   ZK3->(RecLock("ZK3",.T.))
		ZK3->ZK3_FILIAL := xFilial("ZK3")
		ZK3->ZK3_CODIGO := M->ZK1_CODIGO	

		For nConCmp := 1 to Len(aHeader)
			 ZK3->(FieldPut(FieldPos(aHeader[nConCmp,2]), aCols[nConIten, nConCmp]))
		Next 

	   ZK3->(MSUnLock())

	EndIf

Next 

END TRANSACTION

U_ITMsg("DADOS GRAVADOS COM SUCESSO","Atenção",,2)

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS68PPV
Autor-------------: Alex Wallauer
Data da Criacao---: 12/08/2022
===============================================================================================================================
Descrição---------: Função para visualizar Pedidos de Vendas Simples ou Detalhado
===============================================================================================================================
Parametros--------: _oListProd,_cTela
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS68PPV(_oListProd As Object, _cTela As Char, _cChave As Char)
Local _cFil  := cFilant As Char

If _cTela = "D"
   DBSelectArea("SC5")
   SC5->( DBSetOrder(1) )
   If SC5->( DBSeek( _cChave ) ) 
	   cFilant := SubStr(_cChave,1,2)
      MatA410(Nil, Nil, Nil, Nil, "A410Visual")//SE For USAR TEM QUE SALVAR OS MV_PARs E VOLTAR
      cFilant := _cFil
   EndIf   
ElseIf _cTela = "S"
   If _oListProd <> NIL
      MOMS68Item(_oListProd)
   EndIf
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS68Item
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/08/2022
===============================================================================================================================
Descrição---------: Tela dos itens do Pedido e dos itens
===============================================================================================================================
Parametros--------: _oListProd
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS68Item(_oListProd As Object) As Logical
Local aCab         := {} As Array
Local aSize        := NIL As Array
Local aItens       := {} As Array
Local aBotoes      := {} As Array

N:=_oListProd:nAt
_cProduto:=_oListProd:aArray[N,n2PosProd]

ZK2->(DBSetOrder(3))//ZK2_FILIAL+ZK2_CODIGO+ZK2_TIPREG+ZK2_PRODUT
If ZK2->(DBSeek(xFilial("ZK2")+M->ZK1_CODIGO+"P"+_cProduto))

   While ZK2->(ZK2_FILIAL+ZK2_CODIGO+ZK2_TIPREG+ZK2_PRODUT) == xFilial("ZK2")+M->ZK1_CODIGO+"P"+_cProduto .And. !ZK2->(Eof())
          
      aItem:={}
   	aAdd(aItem,ZK2->ZK2_PEDFIL              )//01
   	aAdd(aItem,ZK2->ZK2_PEDIDO              )//02
   	aAdd(aItem,TRANS(ZK2->ZK2_QPED2U,_cPictQTDE))//03
   	aAdd(aItem,ZK2->ZK2_UNIDAD              )//04
   	aAdd(aItem,TRANS(ZK2->ZK2_VRPEDI,_cPictVALOR))//05
   	aAdd(aItem,ZK2->ZK2_NOTA+ZK2->ZK2_SERIE )//06
   	aAdd(aItem,TRANS(ZK2->ZK2_QFAT2U,_cPictQTDE))//07
   	aAdd(aItem,TRANS(ZK2->ZK2_VRFATM,_cPictVALOR))//08
   	aAdd(aItem,TRANS(ZK2->ZK2_VRDEVM,_cPictVALOR))//09
   	aAdd(aItem,TRANS(ZK2->ZK2_RATEIO,_cPictVALOR))//10

      aAdd(aItens,aItem)
      ZK2->(DBSkip())   
   EndDo

ElseIf Len(_aProdMarca) > 0 

   _aProdMarca := aSort(_aProdMarca , , , {|x,y|x[_nPosPRD] < y[_nPosPRD]})//ORDEM DE PRODUTO PARA FAZER While
   _aProd2Marca:= aSort(_aProd2Marca, , , {|x,y|x[_nPosPRD] < y[_nPosPRD]})//ORDEM DE PRODUTO PARA FAZER While
   
   If (nLinha:=aScan(_aProdMarca,{|P| P[_nPosPRD] == _cProduto })) = 0 
      Return .F.
   EndIf
          
   While _aProdMarca[nLinha,_nPosPRD] == _cProduto
          
      If !_aProdMarca[nLinha,1]// *********** LE MARCADOS  ***************
         nLinha++
         If nLinha > Len(_aProdMarca)
            Exit
         EndIf
         Loop
      EndIf
   
      aItem:={}
   	aAdd(aItem,_aProdMarca[nLinha,_nPosFil   ])//01
   	aAdd(aItem,_aProdMarca[nLinha,_nPosPed   ])//02
   	aAdd(aItem,_aProdMarca[nLinha,_nPosUNSVEN])//03
   	aAdd(aItem,_aProdMarca[nLinha,_nPosSEGUM ])//04
   	aAdd(aItem,_aProdMarca[nLinha,_nPosVLRIT ])//05
   	aAdd(aItem,_aProdMarca[nLinha,_nPosNF    ])//06
   	aAdd(aItem,_aProdMarca[nLinha,_nPosQTDEFA])//07
   	aAdd(aItem,_aProdMarca[nLinha,_nPosVLRFA ])//08
   	aAdd(aItem,_aProdMarca[nLinha,_nPosVLRDE ])//09
   	aAdd(aItem,_aProdMarca[nLinha,_nPosVLRat ])//10
      aAdd(aItens,aItem)
   
      nLinha++
      If nLinha > Len(_aProdMarca)
         Exit
      EndIf
   EndDo
Else

   U_ITMsg("Não foi encontrado dados para mostrar.",'Atenção!',"Tente outro produto",3) 

EndIf

If Len(aItens) > 0 

   aAdd(aCab,"Filial"         )//01
   aAdd(aCab,"Pedido"         )//02
   aAdd(aCab,"Qtde. Pedido"   )//03
   aAdd(aCab,"Unidade (2a)"   )//04
   aAdd(aCab,"Vlr. Pedido"    )//05
   aAdd(aCab,"Nota Fiscal"    )//06//NOTA
   aAdd(aCab,"Qtde. Faturada" )//07
   aAdd(aCab,"Vlr. Faturado"  )//08
   aAdd(aCab,"Vlr. Devolvido" )//09 
   aAdd(aCab,"Rateio"         )//10//RATEIO DO ACORDO POR ITEM DE PEDIDO

   _cTitulo:='Pedidos do Item: '+_cProduto
   _cMsgTop:=NIL
   
   //aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS68PPV(,"D", (oLbxAux:aArray[oLbxAux:nAt][1]+oLbxAux:aArray[oLbxAux:nAt][2]) )    },"Lendo Pedido..","Aguarde...")},"","Ver Pedido Completo" })
   
                    //      ,_aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
   U_ITListBox(_cTitulo,aCab,aItens, .T.    , 1   ,_cMsgTop ,          ,aSize  ,         ,     ,        , aBotoes)

EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS68Pesq
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/08/2022
===============================================================================================================================
Descrição---------: Pesquisa GENERICA: PEDIDO / NF / PRODUTO
===============================================================================================================================
Parametros--------: oMsMGet,nCol,cTit
===============================================================================================================================
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function MOMS68Pesq(oMsMGet As Object, nCol As Numeric, cTit As Char) As Logical

Local _oGet1    := Nil As Object
Local _oDlg     := Nil As Object
Local _cGet1    := Space(15) As Char
Local _nOpca    := 0 As Numeric
Local nPos      := 0 As Numeric
Local _lAchou   := .F. As Logical

If oMsMGet <> NIL
   N:=oMsMGet:nAt
   C:=oMsMGet:nColPos
   aColsAux:=oMsMGet:aArray
Else
   Return .F.
EndIf

DEFINE MSDIALOG _oDlg TITLE "Pesquisar" FROM 178,181 TO 259,697 PIXEL 

@004,003 Say cTit Size 213,010 PIXEL OF _oDlg
@020,003 MsGet _oGet1 Var _cGet1				Size 212,009 PIXEL OF _oDlg COLOR CLR_BLACK Picture "@!" F3 "SC5"

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlg:End() ) OF _oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlg:End() ) OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED

If _nOpca == 1

   _cGet1 := AllTrim( _cGet1 )
	  
	If (nPos := aScan(aColsAux,{|P| AllTrim(P[nCol]) == _cGet1 }) ) <> 0 
	   oMsMGet:nAt    := N :=nPos
	   _lAchou:= .T.
	EndIf	  	
				
Else
   Return .F.
EndIf

If _lAchou
   oMsMGet:Refresh()
   oMsMGet:SetFocus()
   //U_ITMsg("O Pedido "+_cGet1+" esta na linha: "+AllTrim(Str(nPos)),'Atenção!',,2) 
Else
   U_ITMsg("Numero não encontrado nesta lista.",'Atenção!',"Tente outro pedido",3) 
EndIf

Return .T.


/*
===============================================================================================================================
Programa--------: MGeraNCC()
Autor-----------: Alex Wallauer
Data da Criacao-: 12/08/2022
===============================================================================================================================
Descrição-------: Tratamento da geracao e deleção dos titulo de NDC
===============================================================================================================================
Parametros------: oproc
==============================================================================================================================
Retorno---------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
Static Function MGeraNCC(oproc As Object) As Logical

Local lOK        := .T. As Logical
Local _nI        := 0 As Numeric
Local _cNaturez  := "231009" As Char //GetMv("IT_NATDCT",,"")
Local _nValor    := 0 As Numeric
Local _nPos      := 0 As Numeric
Local _cParcela  := 0 As Char
Local _cItens    := "" As Char
Local _cNum      := "" As Char
Local _aTitNDC   := {} As Array
Local _cPrefixo  := "VRB" As Char
Local _cTipoNCC  := "NCC" As Char
Local _cFilial   := "92" As Char
Local _cFilAtual := cFilAnt As Char

Private lMsErroAuto := .F. As Logical

cFilAnt:=_cFilial

SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	
ZK3->(DBSetOrder(1))
ZK3->(DBSeek(xFilial("ZK3")+ZK1->ZK1_CODIGO ))
   
While xFilial("ZK3")+ZK1->ZK1_CODIGO == ZK3->ZK3_FILIAL+ZK3->ZK3_CODIGO .And. !ZK3->(Eof())

    If !Empty(Val(ZK3->ZK3_PARCEL))
       _cParcela:=Val(ZK3->ZK3_PARCEL)
       _cParcela:=StrZero(_cParcela,Len(SE1->E1_PARCELA)) 
    Else   
       _cParcela:=Space(Len(SE1->E1_PARCELA)) 
    EndIf
    cChave   :=StrZero(Val(AllTrim(ZK3->ZK3_CONTRA)),Len(SE1->E1_NUM))//AVKEY(ZK1->ZK1_CODIGO,"E1_NUM")
    
  //SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE   +E1_LOJA        +E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
    If SE1->(DBSeek(_cFilial+ZK3->ZK3_FAVORE+ZK3->ZK3_FAVLOJ+_cPrefixo +cChave+_cParcela +_cTipoNCC))
       If Empty(ZK3->ZK3_TITULO) 
          ZK3->(RecLock("ZK3", .F.))           
          ZK3->ZK3_TITFIL:=SE1->E1_FILIAL
          ZK3->ZK3_TITULO:=SE1->E1_NUM
          ZK3->ZK3_TITPAR:=SE1->E1_PARCELA
          ZK3->(MSUnLock())
       EndIf
       ZK3->(DBSkip())
	    Loop
	 EndIf

    _nValor:= ZK3->ZK3_VALOR
    If _nValor = 0
       Loop
    EndIf

    _cNum:=cChave
    If (_nPos:=aScan(_aTitNDC,{|T| T[1]+T[2] == _cNum+_cParcela })) = 0 
       aAdd(_aTitNDC,{ _cNum   ,; // 01
                       _cParcela,; // 02
                       0       ,; // 03
                       DataValida( If(ZK3->ZK3_VENCTO < DATE(),DATE(),ZK3->ZK3_VENCTO) , .T. )  ,; // 04
                       ZK3->(RECNO()),; // 05
                       ZK3->ZK3_FAVORE,; //06
                       ZK3->ZK3_FAVLOJ,; //07
                       ZK3->ZK3_FAVDES }) //08
       _nPos:=Len(_aTitNDC)
    EndIf
    _aTitNDC[_nPos,3]+=_nValor  
  
    ZK3->(DBSkip())
EndDo
    
   
_cItens:=""

BEGIN TRANSACTION
   
   For _nI := 1 TO Len(_aTitNDC)
       lMsErroAuto:=.F.	

      If oproc <> NIL
         oproc:cCaption:=("Gerando NCC: "+_aTitNDC[_nI,1]+_aTitNDC[_nI,2])
         ProcessMessages() 
      EndIf

      SE1->( DBSetOrder(2) )//       E1_FILIAL+E1_CLIENTE   +E1_LOJA          +E1_PREFIXO+E1_NUM         +E1_PARCELA     +E1_TIPO
      If SE1->(DBSeek(_cFilial+_aTitNDC[_nI,6]+_aTitNDC[_nI,7]+_cPrefixo +_aTitNDC[_nI,1]+_aTitNDC[_nI,2]+_cTipoNCC ))

	      _cItens+= "Titulo já existe com a Chave: "+CHR(13)+CHR(10)+_cFilial+" "+_aTitNDC[_nI,6] +" "+_aTitNDC[_nI,7] +" "+_cPrefixo+" "+_aTitNDC[_nI,1]+" "+_aTitNDC[_nI,2]+" "+_cTipoNCC+CHR(13)+CHR(10)
	      lOK := .F.
      Else
	      aArray:= {{"E1_PREFIXO"	,_cPrefixo					      , NIL },;
						{ "E1_NUM"		,_aTitNDC[_nI,1]			      , NIL },;
						{ "E1_PARCELA"	,_aTitNDC[_nI,2]              , NIL },;
						{ "E1_TIPO"		,_cTipoNCC					      , NIL },;
						{ "E1_NATUREZ"	,_cNaturez					      , NIL },;
						{ "E1_CLIENTE"	,_aTitNDC[_nI,6]      		   , NIL },;
						{ "E1_LOJA"		,_aTitNDC[_nI,7] 	            , NIL },;
						{ "E1_NOMCLI"	,_aTitNDC[_nI,8]              , NIL },;
						{ "E1_EMISSAO"	,Date()  					      , NIL },;
						{ "E1_VENCTO"	,_aTitNDC[_nI,4] 			      , NIL },;
						{ "E1_VENCREA"	,_aTitNDC[_nI,4]              , NIL },;
						{ "E1_I_VCPOR"	,datavalida(_aTitNDC[_nI,4])  , Nil },;
						{ "E1_VALOR"	,_aTitNDC[_nI,3]			      , NIL },;
			         { "E1_HIST"    ,"Ref. Acordo: "+ZK1->ZK1_CODIGO+"-"+FWGetSX5( "ZL", ZK1->ZK1_SUBITE)[1,4], NIL }}//,;{ "E1_I_CART","",NIL}}

         MsExecAuto( {|x,y| FINA040( x , y ) } , aArray , 3 )  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
   	   
         If lMsErroAuto
   		   If ( __lSX8 )
   		 	   RollBackSX8()
   		   EndIf
   	      lOK := .F.
   	      _cItens+= +CHR(13)+CHR(10)+"[ "+AllTrim(MostraErro())+" ]"+CHR(13)+CHR(10)

   	   ElseIf lOK

   	      ConfirmSX8()
   	   	SE1->(RecLock("SE1",.F.))
   	   	SE1->E1_PREFIXO:= _cPrefixo
   	   	SE1->E1_TIPO   := _cTipoNCC
   	   	SE1->(MSUnLock())

            ZK3->(DBGoTo(_aTitNDC[_nI,5]))
            ZK3->(RecLock("ZK3", .F.))        
            ZK3->ZK3_TITFIL:=SE1->E1_FILIAL    
            ZK3->ZK3_TITULO:=SE1->E1_NUM
            ZK3->ZK3_TITPAR:=SE1->E1_PARCELA
            ZK3->(MSUnLock())

   	   EndIf
	   EndIf
	   
	   If !lOK
	      Exit
	   EndIf

   Next _nI

   cFilAnt := _cFilAtual

   If !lOK
	   DisarmTransaction()
      bBloco:={||  AVISO("MostraErro()",_cItens,{"Fechar"},3) }
      U_ITMsg("Não foi possivel gerar as NDC clique em Ver Detalhes","MT100GRV005","Verifique a(s) mensagen(s) de erro e tente novamente.",1,,,,,,bBloco)
   Else
      ZK1->(RecLock("ZK1", .F.))            
      ZK1->ZK1_EFETDT:=Date()
      ZK1->ZK1_EFEUSE:=AllTrim(UsrFullName(__cUserId))
      ZK1->ZK1_STATUS:="2"      
      ZK1->(MSUnLock())

      U_MOMS68NT(1,oProc)
   EndIf

END TRANSACTION

Return lOK

/*
===============================================================================================================================
Programa----------: MExcluiNCC()
Autor-------------: Alex Wallauer
Data da Criacao---: 12/08/2022
===============================================================================================================================
Descrição---------: Tratamento da deleção dos titulo de NDC
===============================================================================================================================
Parametros--------: oproc
===============================================================================================================================
Retorno-----------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
Static Function MExcluiNCC(oproc As Object) As Logical
Local lOK := .T. As Logical
Local _nI As Numeric
Local _cTipoNCC := "NCC" As Char
Local _cPrefixo := "VRB" As Char
Local _aRecSE1 := {} As Array
Local _cFilial := "92" As Char
Local _cFilAtual := cFilAnt As Char

Private lMsErroAuto := .F. As Logical

cFilAnt:=_cFilial

SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
ZK3->(DBSetOrder(1))
ZK3->(DBSeek(xFilial("ZK3")+ZK1->ZK1_CODIGO ))
   
While xFilial("ZK3")+ZK1->ZK1_CODIGO == ZK3->ZK3_FILIAL+ZK3->ZK3_CODIGO .And. !ZK3->(Eof())

    cFilAnt   := ZK3->ZK3_TITFIL
    cChave    := ZK3->ZK3_TITULO
    _cParcela := ZK3->ZK3_TITPAR
    
    SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE +E1_LOJA    +E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
    If !SE1->(DBSeek(ZK3->ZK3_TITFIL+ZK3->ZK3_FAVORE+ZK3->ZK3_FAVLOJ+_cPrefixo +cChave+_cParcela +_cTipoNCC))
       ZK3->(DBSkip())
	    Loop
	 EndIf

    aAdd(_aRecSE1, { SE1->(RECNO()) , ZK3->(RECNO()) })
    
    ZK3->(DBSkip())
EndDo
    
BEGIN TRANSACTION

For _nI := 1 To Len(_aRecSE1)

   If oproc <> NIL
      oproc:cCaption:=("Excluindo NCC: "+SE1->E1_NUM+SE1->E1_PARCELA)
      ProcessMessages() 
   EndIf

   SE1->(DBGoTo(_aRecSE1[_nI,1]))
   IncProc("Excluindo Titulo: "+SE1->E1_PREFIXO+" "+SE1->E1_NUM)
   
   _cChave:=SE1->(E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)
   _cChavErro:="Nota: "+SE1->E1_NUM+" / Cliente+Loja: "+SE1->E1_CLIENTE+SE1->E1_LOJA+" / Pref.: "+SE1->E1_PREFIXO+" / Parc.: "+SE1->E1_PARCELA
   
   aArray  := {{ "E1_FILIAL"	,SE1->E1_FILIAL , NIL },;
				   { "E1_NUM"		,SE1->E1_NUM	 , NIL },;
   				{ "E1_PREFIXO"	,SE1->E1_PREFIXO, NIL },;
				   { "E1_PARCELA"	,SE1->E1_PARCELA, NIL },;
				   { "E1_TIPO"		,SE1->E1_TIPO	 , NIL }}

   lMsErroAuto := .F.	
	MsExecAuto( {|x,y| FINA040( x , y ) } , aArray , 5 )  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
	
   SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	If lMsErroAuto .Or. SE1->(DBSeek(_cChave))// SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC+"01NDC" 
	    _cErro:=(MostraErro())
       DisarmTransaction()
       bBloco:={||  AVISO("MostraErro()",_cErro,{"Fechar"},3) }
       U_ITMsg("Não foi possivel excluir o titulo Tipo NCC / "+_cChavErro,"MT100GRV006","Verifique a mensagen de erro [Mais Detalhes] e tente novamente: ",1,,,,,,bBloco)
       lOK:=.F.
       Exit
    Else
       ZK3->(DBGoTo( _aRecSE1[_nI,2] ))
       ZK3->(RecLock("ZK3", .F.))      
       ZK3->ZK3_TITFIL:=""
       ZK3->ZK3_TITULO:=""
       ZK3->ZK3_TITPAR:=""
       ZK3->(MSUnLock())
    EndIf

Next

If lOK
   ZK1->(RecLock("ZK1", .F.))            
   ZK1->ZK1_EFETDT:=CTOD("")
   ZK1->ZK1_EFEUSE:=""
   ZK1->ZK1_STATUS:="1"
   ZK1->(MSUnLock())
EndIf

END TRANSACTION

cFilAnt := _cFilAtual

Return lOK

/*
===============================================================================================================================
Programa----------: MEST21Val()
Autor-------------: Alex Wallauer
Data da Criacao---: 12/08/2022
===============================================================================================================================
Descrição---------: Tratamento da Validacao DO CAMPO chamando do X3_VALID E X3_RELACAO
===============================================================================================================================
Parametros--------: _cCampo
===============================================================================================================================
Retorno-----------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
User Function MEST21Val(_cCampo As Char) As Logical // U_MEST21Val("ZK1_CLIDES")
Local lOK := .T. As Logical
Local P := 0 As Numeric
Local _aProdutos As Array
Local nVrTotRat := 0 As Numeric
Local nPerTotRat := 0 As Numeric
Local nVrMaior := 0 As Numeric
Local nPos := 0 As Numeric
Local nVrAjust := 0 As Numeric
Local nPerAjust := 0 As Numeric

DEFAULT _cCampo := ReadVar() 

If _cCampo == "ZK1_CLIDES"//VALOR NA CAPA RATEIO AUTOMATICO

   M->ZK1_CLIDES:=Posicione("SA1",1,xFilial("SA1")+MV_PAR05+AllTrim(MV_PAR06),"A1_NOME")
   _cCGC := ""
	If Len(AllTrim(SA1->A1_CGC)) = 14	       	
		 _cCGC:= TRANSFORM(AllTrim(SA1->A1_CGC),"@R 99.999.999.9999/99")+" - "
	ElseIf Len(AllTrim(SA1->A1_CGC)) = 11 	       	
		 _cCGC:= TRANSFORM(AllTrim(SA1->A1_CGC),"@R 999.999.999-99")+" / "
	EndIf
   M->ZK1_CLIDES:=_cCGC+AllTrim(M->ZK1_CLIDES)
   Return M->ZK1_CLIDES

ElseIf _cCampo == "M->ZK1_VLRCOR"//VALOR NA CAPA RATEIO AUTOMATICO

   If Type("_oListProd") # "U"
      _aProdutos:=_oListProd:aArray

      IncProc("RATEANDO VALORES...")

      M->ZK1_PERFAT:=(M->ZK1_VLRCOR/M->ZK1_VRAPUR)*100

      For P := 1 TO Len(_aProdutos)//DEPOIS QUE SOMOU TRANSFORMA EM CARACTER OS NUMERICOS
         _aProdutos[P,n2PosVrRa ]:=0
         _aProdutos[P,n2PosPeRa ]:=0
         //_aProdutos[P,n2PosNETAJ]:=0
      Next             
      aTot:={0,0,0,0}//PARA O DEBUG
      For P := 1 to Len(_aProdMarca)
      
         If _aProdMarca[P,1]// *********** LE MARCADOS  ***************
            
            IncProc("RATEANDO VALORES...")
            _aProd2Marca[P][_nPosVLRat] := Round( M->ZK1_VLRCOR *  (_aProd2Marca[P,_nPosVrApur] / M->ZK1_VRAPUR)  ,2) //Rateio do Acordo pelo valor apurado

            If MV_PAR11 = "1"//POR NOTA //Forma de Apuracao: 1=Sobre Faturamento
               _nQtdeApur1um:=_aProd2Marca[P,_nPosQAPU1]//08 - Qtde apurada 1UM  - ZK2_QAPU1U - C6_QTDVEN OU D2_QUANT - D1_QUANT
               _nVrNetAjus   :=Round( ( (_aProd2Marca[P,_nPosVLRFA]-_aProd2Marca[P,_nPosVLRDE])-(_aProd2Marca[P,_nPosVRCTFA]-_aProd2Marca[P,_nPosVRCTDE])-_aProd2Marca[P][_nPosVLRat] ) / _nQtdeApur1um ,3) //(VR FAT S/ IMP - VR DEV S/ IMP - (D2_I_VLRDC - D1_I_VLRDC) - RATEIO) / (QTDE FAT 1UM - QTDE DEV 1 UM)
               _aProd2Marca[P][_nPosNETAJ]:=_nVrNetAjus
            Else//POR PEDIDO //FORMA DE APURACAO: 2=SOBRE PEDIDO
               _nVrNetAjus:=Round((_aProd2Marca[P,_nPosVLRIT]-_aProd2Marca[P,_nPosVRCTPE]-_aProd2Marca[P][_nPosVLRat])/_aProd2Marca[P,_nPosQPED1U],3)// (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO)/C6_QTDVEN // ZK2_NETPED
               _aProd2Marca[P][_nPosNETAJ]:=_nVrNetAjus
            EndIf

            _aProdMarca[P][_nPosVLRat]  := TRANS(_aProd2Marca[P][_nPosVLRat], _cPictVALOR)  
            _aProdMarca[P][_nPosNETAJ]  := TRANS(_aProd2Marca[P][_nPosNETAJ], _cPictVLNET)  
            
            aTot[1]+=_aProd2Marca[P,_nPosVLRat] //Rateio do Acordo
            aTot[2]+=_aProd2Marca[P,_nPosVrApur]//Valor apurado

            If (nPos:=aScan(_aProdutos,{|I| I[1] == _aProd2Marca[P,_nPosPRD] })) <> 0
               _aProdutos[nPos,n2PosVrRa ]+= _aProd2Marca[P][_nPosVLRat] //SOMATORIA POR ITEM DO ACORDO
            EndIf  
      
         EndIf   
      
      Next 

      For P := 1 TO Len(_aProdutos)
      
         If MV_PAR11 = "1"//POR NOTA //Forma de Apuracao: 1=Sobre Faturamento
            _nQtdA1u   :=Val(StrTran(StrTran(_aProdutos[P,n2PosQAPU1 ],".",""),",",".") ) //08 - Qtde apurada 1UM  - ZK2_QAPU1U - C6_QTDVEN OU D2_QUANT - D1_QUANT
            _nVRFAM    :=Val(StrTran(StrTran(_aProdutos[P,n2PosVRFAM ],".",""),",",".") )
            _nVRDEM    :=Val(StrTran(StrTran(_aProdutos[P,n2PosVRDEM ],".",""),",",".") )
            _nVRCTFA   :=Val(StrTran(StrTran(_aProdutos[P,n2PosVRCTFA],".",""),",",".") )
            _nVRCTDE   :=Val(StrTran(StrTran(_aProdutos[P,n2PosVRCTDE],".",""),",",".") )
            _nVrNetAjus:= Round( ( (_nVRFAM - _nVRDEM) - ( _nVRCTFA -_nVRCTDE ) - _aProdutos[P,n2PosVrRa] ) / _nQtdA1u ,3) //(VR FAT S/ IMP - VR DEV S/ IMP - D2_I_VLRDC - D1_I_VLRDC) / (QTDE FAT 1UM - QTDE DEV 1 UM)
            _aProdutos[P,n2PosNETAJ ]:=_nVrNetAjus //07 - Vr Net ajustado   - ZK2_NETAJU - (VALOR P_cPictVLNETEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
         Else//POR PEDIDO //FORMA DE APURACAO: 2=SOBRE PEDIDO
            _nVrNetAjus:=Round(( Val(StrTran(StrTran(_aProdutos[P,n2PosVPed],".",""),",",".") ) -Val(StrTran(StrTran(_aProdutos[P,n2PosCPed],".",""),",",".") ) -_aProdutos[P,n2PosVrRa] )/Val(StrTran(StrTran(_aProdutos[P,n2PosQ1Ped],".",""),",",".") ) ,3 )// (VALOR PEDIDOS - VR CONTR PEDIDO - RATEIO)/C6_QTDVEN // ZK2_NETPED
            _aProdutos[P,n2PosNETAJ ]:=_nVrNetAjus //07 - Vr Net ajustado   - ZK2_NETAJU - (VALOR PEDIDOS - VR CONTR PEDIDO) / QTDE PED 1UM	
         EndIf

         _aProdutos[P,n2PosPeRa ]:= Round( (_aProdutos[P,n2PosVrRa] / M->ZK1_VLRCOR )*100 ,3)//PERCENTUAL por item do Acordo

         If nVrMaior < _aProdutos[P,n2PosVrRa] //MAIOR RATEIO DO ACORDO
            nVrMaior := _aProdutos[P,n2PosVrRa]
            nPos := P
         EndIf
         nVrTotRat += _aProdutos[P,n2PosVrRa] //SOMATORIA POR PRODUTO DO ACORDO
         nPerTotRat += _aProdutos[P,n2PosPeRa ]

         //DEPOIS QUE SOMOU TRANSFORMA EM CARACTER OS NUMERICOS
         _aProdutos[P,n2PosPeRa ]:= TRANS(_aProdutos[P,n2PosPeRa ] , _cPictVLNET)
         _aProdutos[P,n2PosVrRa ]:= TRANS(_aProdutos[P,n2PosVrRa ] , _cPictVALOR)
         _aProdutos[P,n2PosNETAJ]:= TRANS(_aProdutos[P,n2PosNETAJ] , _cPictVLNET)
         
      Next             

      If nVrTotRat <> M->ZK1_VLRCOR
         nVrAjust := M->ZK1_VLRCOR - nVrTotRat
         _aProdutos[nPos,n2PosVrRa] := Val(StrTran(StrTran(_aProdutos[nPos,n2PosVrRa ],".",""),",",".")) + nVrAjust
         _aProdutos[nPos,n2PosVrRa ]:= TRANS(_aProdutos[nPos,n2PosVrRa ] , _cPictVALOR) 
      EndIf

      If nPerTotRat <> 100
         nPerAjust := 100 - nPerTotRat
         _aProdutos[nPos,n2PosPeRa] := Val(StrTran(StrTran(_aProdutos[nPos,n2PosPeRa ],".",""),",",".")) + nPerAjust
         _aProdutos[nPos,n2PosPeRa] := TRANS(_aProdutos[nPos,n2PosPeRa ] , _cPictVLNET)
      EndIf

      _oListProd:aArray:=_aProdutos
      _oListProd:Refresh()

   EndIf

ElseIf _cCampo == "M->ZK1_FAVORE"

   _cCampo:=M->ZK1_FAVORE
   M->ZK1_FAVORE:=LEFT(_cCampo,Len(SA1->A1_COD))
   If (lOK:=ExistCpo("SA1",AllTrim(_cCampo)))
      If Len(_cCampo) > Len(SA1->A1_COD)
         M->ZK1_FAVLOJ:=SubStr(_cCampo,Len(SA1->A1_COD)+1)
         M->ZK1_FAVDES:=Posicione("SA1",1,xFilial("SA1")+_cCampo,"A1_NREDUZ")
         If Empty(AllTrim(M->ZK1_CVENDE))
            M->ZK1_CVENDE:=Posicione("SA1",1,xFilial("SA1")+M->ZK1_FAVORE+M->ZK1_FAVLOJ,"A1_VEND")
            M->ZK1_VENDER:=Posicione("SA3",1,xFilial("SA3") +M->ZK1_CVENDE,"A3_NOME")
         EndIf
      EndIf
   EndIf

ElseIf _cCampo == "M->ZK1_FAVLOJ"

    If (lOK:=ExistCpo("SA1",M->ZK1_FAVORE+M->ZK1_FAVLOJ))
       M->ZK1_FAVDES:=Posicione("SA1",1,xFilial("SA1")+M->ZK1_FAVORE+M->ZK1_FAVLOJ,"A1_NREDUZ")
       If Empty(AllTrim(M->ZK1_CVENDE))
          M->ZK1_CVENDE:=Posicione("SA1",1,xFilial("SA1")+M->ZK1_FAVORE+M->ZK1_FAVLOJ,"A1_VEND")
          M->ZK1_VENDER:=Posicione("SA3",1,xFilial("SA3") +M->ZK1_CVENDE,"A3_NOME")
       EndIf
    EndIf

ElseIf _cCampo == "M->ZK3_FAVORE"
   _cCampo := M->ZK3_FAVORE
   M->ZK3_FAVORE :=LEFT(_cCampo,Len(SA1->A1_COD))
   
    If (lOK:=ExistCpo("SA1",AllTrim(_cCampo)))
       If Len(_cCampo) > Len(SA1->A1_COD)
         M->ZK3_FAVLOJ :=SubStr(_cCampo,Len(SA1->A1_COD)+1)
         M->ZK3_FAVDES := Posicione("SA1",1,xFilial("SA1")+_cCampo,"A1_NREDUZ")
         oMSMGET:ACOLS[oMSMGET:nAt][_nPosLojaFav]:=SubStr(_cCampo,Len(SA1->A1_COD)+1)
         oMSMGET:ACOLS[oMSMGET:nAt][_nPosNomFav]:=Posicione("SA1",1,xFilial("SA1")+_cCampo,"A1_NREDUZ")
       EndIf
    EndIf
    oMSMGET:ACOLS[oMSMGET:nAt][_nPosFavorec]:=LEFT(_cCampo,Len(SA1->A1_COD))
    oMSMGET:Refresh()
EndIf

Return lOK
/*
===============================================================================================================================
Programa--------: MOM68ZK2
Autor-----------: Alex Wallauer
Data da Criacao-: 12/08/2022
===============================================================================================================================
Descrição-------: Controle de Acordos Comerciais - ITENS
===============================================================================================================================
Parametros------: NENHUM
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MOM68ZK2()// U_MOM68ZK2

aRotina := {{ "Pesquisar"           ,"AxPesqui", 0 , 1 },; 
            { "Visualizar"          ,'AxVisual', 0 , 2 },; 
            { "Incluir"             ,'AxInclui', 0 , 3 },; 
            { "Alterar"             ,'AxAltera', 0 , 4 },; 
            { "Excluir"             ,'AxDeleta', 0 , 5 }}
           
cCadastro :="Controle de Acordos Comerciais - ITENS"

mBrowse(,,,,"ZK2")

Return

/*
===============================================================================================================================
Programa--------: MOM68ZK3
Autor-----------: Alex Wallauer
Data da Criacao-: 12/08/2022
===============================================================================================================================
Descrição-------: Controle de Acordos Comerciais - PARCELAS
===============================================================================================================================
Parametros------: NENHUM
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MOM68ZK3()// U_MOM68ZK3

aRotina := {{ "Pesquisar"           ,"AxPesqui", 0 , 1 },; 
            { "Visualizar"          ,'AxVisual', 0 , 2 },; 
            { "Incluir"             ,'AxInclui', 0 , 3 },; 
            { "Alterar"             ,'AxAltera', 0 , 4 },; 
            { "Excluir"             ,'AxDeleta', 0 , 5 }}
           
cCadastro :="Controle de Acordos Comerciais - ITENS"

mBrowse(,,,,"ZK3")

Return

/*
===============================================================================================================================
Programa--------: MOM68Query()
Autor-----------: Alex Wallauer
Data da Criacao-: 12/08/2022
===============================================================================================================================
Descrição-------: Retorna a Query princical
===============================================================================================================================
Parametros------: NENHUM
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MOM68Query(_lEncaminhar As Logical) As Char
Local _cQuery := "" As Char
Local _cAlias2 := GetNextAlias() As Char
DEFAULT _lEncaminhar := .F. 

If _lEncaminhar
   _cQuery += " SELECT R_E_C_N_O_ ZK1_REC FROM ZK1010 ZK1"
   _cQuery += "    WHERE ZK1_STATUS = '1' "
   _cQuery += "    AND ZK1.D_E_L_E_T_ = ' ' "
   _cQuery += " ORDER BY ZK1_CODIGO "

    MPSysOpenQuery( _cQuery , _cAlias2)
    
    (_cAlias2)->(DBGoTop())
    If (_cAlias2)->(Eof())
       U_ITMsg("Não tem acordos em elaborcao para processamento.","ATENCAO",,3) 
    	 Return {}
    EndIf
    	
    aItens:={}
    While (_cAlias2)->(!Eof()) //**********************************  While  ******************************************************

      ZK1->(DBGoTo( (_cAlias2)->ZK1_REC )) 
      aItem:={}
   	aAdd(aItem,.F.)//01
   	aAdd(aItem,ZK1->ZK1_CODIGO)//02
   	aAdd(aItem,AllTrim(ZK1->ZK1_GERENT))//03
   	aAdd(aItem,AllTrim(ZK1->ZK1_REDES) )//04
   	aAdd(aItem,AllTrim(Posicione("SA1",1,xFilial("SA1")+ZK1->ZK1_CLIENT+AllTrim(ZK1->ZK1_CLILOJ),"A1_NREDUZ")))//05
   	aAdd(aItem,TRANS(ZK1->ZK1_VLRCOR,_cPictVALOR))//06
   	aAdd(aItem,ZK1->ZK1_OBS )//07
   	aAdd(aItem,ZK1->(RECNO()) )//08

      aAdd(aItens,aItem)

    	(_cAlias2)->(DBSkip())
    EndDo
    (_cAlias2)->(DBCloseArea())

   Return  aItens

EndIf

_cQuery += " SELECT DISTINCT C5_FILIAL,C5_NUM,C5_EMISSAO, C5_CLIENTE,C5_LOJACLI,C5_I_NOME "
_cQuery += " 	FROM SC6010 SC6, SC5010 SC5, SD2010 SD2, SB1010 SB1, ZAY010 ZAY "
_cQuery += "    WHERE C5_TIPO = 'N' "
_cQuery += "          AND SC5.D_E_L_E_T_ = ' ' "
_cQuery += "          AND C6_FILIAL = C5_FILIAL "
_cQuery += "          AND C6_NUM = C5_NUM "
_cQuery += "          AND SC6.D_E_L_E_T_ = ' ' "
_cQuery += "          AND B1_FILIAL = ' ' "
_cQuery += "          AND B1_COD = C6_PRODUTO "
_cQuery += "          AND B1_TIPO = 'PA' "
_cQuery += "          AND SB1.D_E_L_E_T_ = ' ' "
_cQuery += "          AND ZAY_FILIAL = ' ' "
_cQuery += "          AND ZAY_CF = C6_CF "
_cQuery += "          AND ZAY.D_E_L_E_T_ = ' ' "
_cQuery += "          AND (ZAY_TPOPER = 'V' OR C5_I_OPER = '42') "
_cQuery += "          AND D2_FILIAL(+) = C6_FILIAL "
_cQuery += "          AND D2_SERIE(+) = C6_SERIE "
_cQuery += "          AND D2_DOC(+) = C6_NOTA "
_cQuery += "          AND D2_COD(+) = C6_PRODUTO "
_cQuery += "          AND SD2.D_E_L_E_T_(+) = ' ' "

 If MV_PAR11 = "1" .And. !Empty(MV_PAR01)//NOTA //Forma de Apuracao: 1=Sobre Faturamento
    _cQuery += "  AND D2_EMISSAO >= '" + DToS(MV_PAR01)+"' "
 EndIf
 If MV_PAR11 = "1" .And. !Empty(MV_PAR02)//NOTA //Forma de Apuracao: 1=Sobre Faturamento
    _cQuery += "  AND D2_EMISSAO <= '" + DToS(MV_PAR02)+"' "
 EndIf
 
 If MV_PAR11 = "2" .And. !Empty(MV_PAR01)//PEDIDOS //FORMA DE APURACAO: 2=SOBRE PEDIDO
    _cQuery += "  AND C5_EMISSAO >= '" + DToS(MV_PAR01)+"' "
 EndIf
 If MV_PAR11 = "2" .And. !Empty(MV_PAR02)//PEDIDOS //FORMA DE APURACAO: 2=SOBRE PEDIDO
    _cQuery += "  AND C5_EMISSAO <= '" + DToS(MV_PAR02)+"' "
 EndIf

 If !Empty(MV_PAR03)
    _cQuery += "  AND C5_FILIAL IN " + FormatIn(MV_PAR03, ";") + " " 
 EndIf
 
 // Rede
 If !Empty( MV_PAR04 )                                                   
 	If Len(AllTrim(MV_PAR04)) <= 6
 		_cQuery += " AND C5_I_GRPVE	= '" + AllTrim(MV_PAR04) + "' "
 	Else
 		_cQuery += " AND C5_I_GRPVE	IN " + FormatIn( MV_PAR04 , ";" )
 	EndIf
 EndIf
 
 // CLIENTE
 If !Empty( MV_PAR05 )                                                   
    _cQuery += " AND C5_CLIENTE	= '" + AllTrim(MV_PAR05) + "' "
 EndIf
 
 // LOJA
 If !Empty( MV_PAR06 )                                                   
    _cQuery += " AND C5_LOJACLI	= '" + AllTrim(MV_PAR06) + "' "
 EndIf
 
 // Filtra Gerente
 If !Empty( MV_PAR07 )             
 	If Len(AllTrim(MV_PAR07)) <= 6
 		_cQuery += " AND C5_VEND3 = '"+ AllTrim(MV_PAR07) + "' "
 	Else
 		_cQuery += " AND C5_VEND3 IN "+ FormatIn( MV_PAR07 , ";" )
 	EndIf
 EndIf
 
 // Filtra Coordenador
 If !Empty( MV_PAR08 )             
 	If Len(AllTrim(MV_PAR08)) <= 6
 		_cQuery += " AND C5_VEND2 = '"+ AllTrim(MV_PAR08) + "' "
 	Else
 		_cQuery += " AND C5_VEND2 IN "+ FormatIn( MV_PAR08 , ";" )
 	EndIf
 EndIf
 
 // Filtra Vendedor
 If !Empty( MV_PAR09 )      
 	If Len(AllTrim(MV_PAR09)) <= 6
 		_cQuery += " AND C5_VEND1 = '"+ AllTrim(MV_PAR09) + "' "
 	Else
 		_cQuery += " AND C5_VEND1 IN "+ FormatIn(AllTrim(MV_PAR09), ";" )
 	EndIf
 EndIf
 
 // Filtra PRODUTO
 If !Empty( MV_PAR10 )      
 	If Len(AllTrim(MV_PAR10)) <= 11
 		_cQuery += " AND C6_PRODUTO = '"+ AllTrim(MV_PAR10) + "' "
 	Else
 		_cQuery += " AND C6_PRODUTO IN "+ FormatIn(AllTrim(MV_PAR10), ";" )
 	EndIf
 EndIf
 
 _cQuery += " ORDER BY C5_NUM "

Return _cQuery


/*
===============================================================================================================================
Programa----------: MOMS68NF
Autor-------------: Igor Melgaço
Data da Criacao---: 12/09/2022
===============================================================================================================================
Descrição---------: Visualiza Browse por Nota 
===============================================================================================================================
Parametros--------: oMsMGet,oSayAux,_cMsgTop
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS68NF(oMsMGet As Object, oSayAux As Object, _cMsgTop As Char) As Logical
Local _aNF      := {} As Array
Local _aPedTemp := {} As Array
Local i         := 0 As Numeric
Local j         := 0 As Numeric
Local _aCab     := {"","Nota Fiscal","Cliente","Loja","Nome" } As Array
Local _cTitulo  := "MARCACAO POR NOTA" As Char
Local aSize     := {30,50,50,30,300} As Array
Local aBotoes   := {} As Array
Local _cNFAnter := "" As Char
Local nCol      := _nPosNF As Numeric

_aPedTemp := aClone(_aProdMarca)
_aPedTemp := aSort(_aPedTemp,,,{|x, y| x[nCol] < y[nCol]})

For i := 1 To Len(_aPedTemp)
   
   If _aPedTemp[i,nCol] <> _cNFAnter .And. AllTrim(_aPedTemp[i,nCol]) <> "-" .And. _aPedTemp[i,2]
      aAdd(_aNF,{.F.,_aPedTemp[i,nCol],_aPedTemp[i,_nPoscLI],_aPedTemp[i,_nPosLoj],_aPedTemp[i,_nPosNomeCli]})
      _cNFAnter := _aPedTemp[i,nCol]
   EndIf


Next
If Len(_aNF) = 0
   U_ITMsg("Sem notas disponiveis para selecionar","Atenção","Somente linhas com bolinha verde podem serem selecionadas.",3)
   Return .F.
EndIf
aAdd(aBotoes,{"",{|| MOMS68Pesq(oLbxAux,2,"NOTAL FISCAL") },"","PESQUISAR"})
    
_aNF := aSort(_aNF,,,{|x, y| x[2] < y[2]})

                     //      ,_aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
If U_ITListBox(_cTitulo,_aCab,_aNF  , .F.    , 2    ,        ,          ,aSize   ,         ,     ,        , aBotoes)

   For i := 1 To Len(_aNF)
      If _aNF[i,1]
         For j := 1 To Len(_aProdMarca)
            If _aNF[i,2] == _aProdMarca[j,nCol] .And. _aProdMarca[j,2]
               If !_aProdMarca[j,1]//Só soma os que não estão MARCADOS
                  _nTotalM += Val(StrTran(StrTran(_aProdMarca[j][_nPosVrApur],".",""),",","."))
               EndIf
               _aProdMarca[j,1] := .T.
            EndIf
         Next
      EndIf
   Next

   _cMsgTop :=  "Total dos itens apurados selciondados: "+ AllTrim(Transform(  _nTotalM  , _cPictTOTAL ))
   oSayAux:Refresh()
   oMsMGet:Refresh()

EndIf

Return .T.



/*
===============================================================================================================================
Programa----------: MOMS68PED
Autor-------------: Igor Melgaço
Data da Criacao---: 12/09/2022
===============================================================================================================================
Descrição---------: Visualiza Browse PEDIDO
===============================================================================================================================
Parametros--------: oMsMGet,oSayAux,_cMsgTop
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS68PED(oMsMGet As Object, oSayAux As Object, _cMsgTop As Char) As Logical
Local _aPed      := {} As Array
Local _aPedTemp  := {} As Array
Local i          := 0 As Numeric
Local j          := 0 As Numeric
Local _aCab      := {"", "Pedido", "Cliente", "Loja", "Nome"} As Array
Local _cTitulo   := "MARCACAO POR PEDIDO" As Char
Local aSize      := {30, 50, 50, 30, 300} As Array
Local aBotoes    := {} As Array
Local _cPedAnter := "" As Char
Local nCol       := _nPosPed As Numeric
If Len(_aProdMarca) = 0
   Return .F.
EndIf
_aPedTemp := aClone(_aProdMarca)
_aPedTemp := aSort(_aPedTemp,,,{|x, y| x[nCol] < y[nCol]})

For i := 1 To Len(_aPedTemp)
   
   If _aPedTemp[i,nCol] <> _cPedAnter .And. _aPedTemp[i,2]
      aAdd(_aPed,{.F.,_aPedTemp[i,nCol],_aPedTemp[i,_nPoscLI],_aPedTemp[i,_nPosLoj],_aPedTemp[i,_nPosNomeCli]})
      _cPedAnter := _aPedTemp[i,nCol]
   EndIf

Next

If Len(_aPed) = 0
   U_ITMsg("Sem Pedidos disponiveis para selecionar","Atenção","Somente linhas com bolinha verde podem serem selecionadas.",3)
   Return .F.
EndIf

aAdd(aBotoes,{"",{|| MOMS68Pesq(oLbxAux,2,"PEDIDO:") },"","PESQUISAR"               })

_aPed := aSort(_aPed,,,{|x, y| x[2] < y[2]})

                     //      ,_aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
If U_ITListBox(_cTitulo,_aCab,_aPed  , .F.    , 2    ,       ,          ,aSize  ,         ,     ,        , aBotoes)

   For i := 1 To Len(_aPed)
      If _aPed[i,1]
         For j := 1 To Len(_aProdMarca)
            If _aPed[i,2] == _aProdMarca[j,nCol] .And. _aProdMarca[j,2]
               If !_aProdMarca[j,1]//Só soma os que não estão MARCADOS
                  _nTotalM += Val(StrTran(StrTran(_aProdMarca[j][_nPosVrApur],".",""),",","."))
               EndIf
               _aProdMarca[j,1] := .T.
            EndIf
         Next
      EndIf
   Next

   _cMsgTop :=  "Total dos itens apurados selciondados: "+ AllTrim(Transform(  _nTotalM  , _cPictTOTAL ))
   oSayAux:Refresh()
   oMsMGet:Refresh()

EndIf

Return .T.
/*
===============================================================================================================================
Programa----------: MOMS68PItem
Autor-------------: Alex Wllauer
Data da Criacao---: 21/10/2022
===============================================================================================================================
Descrição---------: Visualiza Browse PRODUTO
===============================================================================================================================
Parametros--------: oMsMGet,oSayAux,_cMsgTop
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS68PItem(oMsMGet As Object, oSayAux As Object, _cMsgTop As Char) As Logical
Local _aItem    := {} As Array
Local _aItemTemp:= {} As Array
Local i         := 0 As Numeric
Local j         := 0 As Numeric
Local _aCab     := {"","Cod. Produto","Descricao do Produto"} As Array
Local _cTitulo  := "MARCACAO POR PRODUTO" As Char
Local aSize     := {20,50,300} As Array
Local aBotoes   := {} As Array
Local _cChave   := "" As Char
Local nCol      := _nPosPRD As Numeric
If Len(_aProdMarca) = 0
   Return .F.
EndIf
_aItemTemp := aClone(_aProdMarca)
_aItemTemp := aSort(_aItemTemp,,,{|x, y| x[nCol] < y[nCol]})

For i := 1 To Len(_aItemTemp)
   
   If _aItemTemp[i,nCol] <> _cChave .And. _aItemTemp[i,2]
      aAdd(_aItem,{.F.,_aItemTemp[i,nCol],_aItemTemp[i,_nPosDES]})
      _cChave := _aItemTemp[i,nCol]
   EndIf

Next

If Len(_aItem) = 0
   U_ITMsg("Sem Produtos disponiveis para selecionar","Atenção","Somente linhas com bolinha verde podem serem selecionadas.",3)
   Return .F.
EndIf

aAdd(aBotoes,{"",{|| MOMS68Pesq(oLbxAux,2,"PRODUTO:") },"","PESQUISAR"               })

_aItem := aSort(_aItem,,,{|x, y| x[2] < y[2]})

                     //      ,_aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
If U_ITListBox(_cTitulo,_aCab,_aItem  , .F.    , 2    ,       ,          ,aSize  ,         ,     ,        , aBotoes)

   For i := 1 To Len(_aItem)
      If _aItem[i,1]
         For j := 1 To Len(_aProdMarca)
            If _aItem[i,2] == _aProdMarca[j,nCol] .And. _aProdMarca[j,2]
               If !_aProdMarca[j,1]//Só soma os que não estão MARCADOS
                  _nTotalM += Val(StrTran(StrTran(_aProdMarca[j][_nPosVrApur],".",""),",","."))
               EndIf
               _aProdMarca[j,1] := .T.
            EndIf
         Next
      EndIf
   Next

   _cMsgTop :=  "Total dos itens apurados selciondados: "+ AllTrim(Transform(  _nTotalM  , _cPictTOTAL ))
   oSayAux:Refresh()
   oMsMGet:Refresh()

EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS68Legenda
Autor-------------: Alex Wallauer
Data da Criacao---: 23/01/2023
===============================================================================================================================
Descrição---------: Legenda do browse
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS68Legenda()
//1=Em Elaboracao
//2=Efetivado
//3=Recusado
//4=Encaminhado
//5=Provisao
aLegenda:={{ 'BR_AMARELO' , "Em Elaboracao"},;
			  { 'BR_VERDE'   , "Efetivado"    },;
			  { 'BR_VERMELHO', "Recusado"     },;
           { 'BR_AZUL'    , "Encaminhado"  },;
			  { 'BR_BRANCO'  , "Provisao"     } }

BrwLegenda("Todos os Status","Legenda",aLegenda)

Return .T.


/*
===============================================================================================================================
Programa----------: MOMS68NT
Autor-------------: Igor Melgaco
Data da Criacao---: 16/11/2023
===============================================================================================================================
Descrição---------: Prepara a Abertura da Compensação
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS68NT(nOper As Numeric, oProc As Object) As Logical
Local _cFilAnt := "" As Char

Default nOper := 1
 
   If nOper = 2
      If (ZK1->ZK1_STATUS == "2" .Or. ZK1->ZK1_STATUS == "6") 
         If ZK1->ZK1_FORPAG == "2" 
            __cNumCont := ZK1->ZK1_CODIGO
         Else
            U_ITMsg("Esse contrato não possui forma de pagamento com finalidade desconto!","Atenção","",3)
         EndIf
      Else
         __cNumCont := ""
         U_ITMsg("Esse contrato não foi efetivado para Compensação!","Atenção","",3)
      EndIf
   Else
      If M->ZK1_FORPAG == "2"
         __cNumCont := M->ZK1_CODIGO
      Else
         __cNumCont := ""
         U_ITMsg("Esse contrato não possui forma de pagamento com finalidade desconto!","Atenção","",3)
      EndIf
   EndIf

   If !Empty(AllTrim(__cNumCont))
   	_cFilAnt := cFilAnt
		cFilAnt  := '92'

      U_MOMS68EM(.F.,oMsMGet:aCols)
   EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS68EM
Autor-------------: Igor Melgaco
Data da Criacao---: 16/11/2023
===============================================================================================================================
Descrição---------: Envio de Email
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: lRet
===============================================================================================================================
*/
User Function MOMS68EM(_lCompensa As Logical, aCols As Array, _lExibeResult As Logical) As Logical
Local i           := 0 As Numeric
Local _aConfig    := {} As Array
Local _cTit       := "" As Char
Local _cMsgEml    := "" As Char
Local _cGetAssun  := "" As Char
Local _cEmlLog    := "" As Char
Local _nRecAnt    := 0 As Numeric
Local _cGetPara   := "" As Char
Local _cGetCC     := U_ItGetMv("IT_MOMS68C", "sistema@italac.com.br") As Char
Local _cGetSup    := U_ItGetMv("IT_MOMS68S", "sistema@italac.com.br") As Char
Local _cNome      := "" As Char
Local _nTotal     := 0 As Numeric
Local _cValor     := "" As Char
Local _cPrefixo   := "VRB" As Char
Local _cTipoNCC   := "NCC" As Char
Local _cFilial    := "92" As Char
Local _lRet       := .F. As Logical

Default _lCompensa := .F.
Default aCols := {}
Default _lExibeResult := .F.

   _cNome     :=  Posicione("SA1",1,xFilial("SA1")+ZK1->ZK1_FAVORE+AllTrim(ZK1->ZK1_FAVLOJ),"A1_NOME")
   _cTit      := "Aprovação de Contrato"

   _cVendedor  := Posicione("SA1",1,xFilial("SA1")+ZK1->ZK1_FAVORE+AllTrim(ZK1->ZK1_FAVLOJ),"A1_VEND") 
	_cEmailVend := AllTrim(Posicione("SA3",1,xFilial("SA3")+_cVendedor,"A3_EMAIL"))
   
   _cSup       := Posicione("SA3",1,xFilial("SA3")+_cVendedor,"A3_I_SUPE")

   If Empty(AllTrim(_cSup))
      _cEmailSup  := ""
   Else
      _cEmailSup  := AllTrim(Posicione("SA3",1,xFilial("SA3")+_cSup,"A3_EMAIL"))
   EndIf

   _cCood := Posicione("SA3",1,xFilial("SA3")+_cVendedor,"A3_SUPER")
   
   If Empty(AllTrim(_cCood))
      _cEmailCood  := ""
   Else
      _cEmailCood  := AllTrim(Posicione("SA3",1,xFilial("SA3")+_cCood,"A3_EMAIL"))
   EndIf

   _cGer  := Posicione("SA3",1,xFilial("SA3")+_cVendedor,"A3_GEREN")
   
   If Empty(AllTrim(_cGer))
      _cEmailGer  := ""
   Else
      _cEmailGer  := AllTrim(Posicione("SA3",1,xFilial("SA3")+_cGer,"A3_EMAIL"))
   EndIf

   If _lCompensa
      _cGetPara  := MOMS068FM(_cGetPara,_cGetSup)
      _cGetCc    := MOMS068FM(_cGetCc,{_cEmailSup,_cEmailCood,_cEmailGer}) 
      _cValor    := TRANS(ZK1->ZK1_VLRCOR,_cPictVALOR)
      _cGetAssun := "Verba cliente " + _cNome + " valor " + _cValor + " já foi abatida, favor fazer compensação."
   Else  
      _cGetPara  := MOMS068FM(_cGetPara,{_cEmailSup,_cEmailCood,_cEmailGer})  
      _cGetAssun := "Aprovação do Contrato "+ZK1->ZK1_CODIGO + " - Favorecido "+ ZK1->ZK1_FAVORE + " " + ZK1->ZK1_FAVLOJ + "  " + _cNome
   EndIf

   If ZK1->ZK1_ABATIM = "1"
      //_cGetPara := _cGetSup
      _cGetPara := _cGetSup + ";" +_cGetPara 
   EndIf

   _aConfig	:= U_ITCFGEML('')

	//Logo Italac
	_cMsgEml := '<html>'
	_cMsgEml += '<head><title>'+_cTit+'</title></head>'
	_cMsgEml += '<body>'
	_cMsgEml += '<style Type="text/css"><!--'
	_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
	_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
	_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
	_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
	_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
	_cMsgEml += '--></style>'
	_cMsgEml += '<center>'
	_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
	_cMsgEml += '<br>'

	//Celula Azul para Título
	_cMsgEml += '<table class="bordasimples" width="600">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '	     <td class="titulos"><center>'+_cTit+'</center></td>'
	_cMsgEml += '	 </tr>'
	_cMsgEml += '</table>'
	_cMsgEml += '<br>'

	_cMsgEml += '</center>'
	_cMsgEml += '<br>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="left" > <b>Contrato</b> '+ZK1->ZK1_CODIGO +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '<br>'

	//Rede
   If !Empty(AllTrim(ZK1->ZK1_REDES))
   	_cMsgEml += '<br>'
   	_cMsgEml += '    <tr>'
   	_cMsgEml += '      <td class="itens" align="left" > <b>Rede </b> '+ ZK1->ZK1_REDES + '</td>'
   	_cMsgEml += '    </tr>'
   	_cMsgEml += '<br>'
   EndIf

	//Favorecido
	_cMsgEml += '<br>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="left" > <b>Favorecido </b> '+ ZK1->ZK1_FAVORE + " " + ZK1->ZK1_FAVLOJ + "  " + _cNome + '</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '<br>'

   _nRecAnt := 0

   If _lCompensa
      For i := 1 To Len(aCols)
         
         If _nRecAnt <>  aCols[i,1]

            _cMsgEml += '<br>'
            _cMsgEml += '    <tr>'
            _cMsgEml += '      <td class="itens" align="left" > <b></b> ======================================================================= </td>'
            _cMsgEml += '    </tr>'
            _cMsgEml += '<br>'

            _cMsgEml += '<br>'
            _cMsgEml += '    <tr>'
            _cMsgEml += '      <td class="itens" align="left" > <b>Título </b> '+ SE1->E1_NUM + IIf(Empty(AllTrim(SE1->E1_PARCELA)),""," Parcela ") + SE1->E1_PARCELA + "      Saldo Atual " + Transform(SE1->E1_SALDO,"@E 9,999,999,999.99")  + '</td>'
            _cMsgEml += '    </tr>'
            _cMsgEml += '<br>'

            _cMsgEml += '<br>'
            _cMsgEml += '    <tr>'
            _cMsgEml += '      <td class="itens" align="left" > <b>Compensado com os títulos</b> '+ '</td>'
            _cMsgEml += '    </tr>'
            _cMsgEml += '<br>'

         EndIf

         SE1->(DBGoTo(aCols[i,2]))

         _cMsgEml += '<br>'
         _cMsgEml += '    <tr>'
         _cMsgEml += '      <td class="itens" align="left" > <b></b> '+  SE1->E1_NUM + IIf(Empty(AllTrim(SE1->E1_PARCELA)),""," Parcela ") + SE1->E1_PARCELA + " Valor " + Transform(__aContrat[i,3],"@E 9,999,999,999.99")  + " Vencto "+DToC(SE1->E1_VENCREA) + '</td>'
         _cMsgEml += '    </tr>'
         _cMsgEml += '<br>'

         _nRecAnt :=  aCols[i,1]
         _nTotal += aCols[i,3]
      Next
   Else
      For i := 1 To Len(aCols)
         DBSelectArea("SE1")
         DBSetOrder(1)
         If DBSeek(_cFilial+_cPrefixo+aCols[i][1]+aCols[i][2]+_cTipoNCC+ZK1->ZK1_FAVORE+ZK1->ZK1_FAVLOJ)
            
            _cMsgEml += '<br>'
            _cMsgEml += '    <tr>'
            _cMsgEml += '      <td class="itens" align="left" > <b>Título </b> '+ SE1->E1_NUM + IIf(Empty(AllTrim(SE1->E1_PARCELA)),""," Parcela ") + SE1->E1_PARCELA + " Saldo Atual " + Transform(SE1->E1_SALDO,"@E 9,999,999,999.99")  + '</td>'
            _cMsgEml += '    </tr>'
            _cMsgEml += '<br>'

         EndIf
      Next
   EndIf

	_cMsgEml += '</center>'
	_cMsgEml += '<br>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" > <b></b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '<br>'
	_cMsgEml += '<br>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MOMS68]</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '</body>'
	_cMsgEml += '</html>'

   U_ITENVMAIL( _aConfig[01], _cGetPara, _cGetCc, "", _cGetAssun, _cMsgEml, ""    , _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

   If _lExibeResult
      U_ITMsg( _cEmlLog , 'Término do processamento!' ,"Enviado para "+_cGetPara ,2 )
   EndIf

Return _lRet


/*
===============================================================================================================================
Programa----------: MOMS68CS
Autor-------------: Igor Melgaco
Data da Criacao---: 05/01/2023
===============================================================================================================================
Descrição---------: Atualiza Status de Compensação dos Contratos
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS68CS(nRecnoSE1 As Numeric) As Logical
Local _aAreaSE1 := SE1->(GetArea()) As Array

DBSelectArea("SE1")
DBGoTo(nRecnoSE1)
If "Ref. Acordo: " $ SE1->E1_HIST

   DBSelectArea("ZK1")
   DBSetOrder(1)
   If DBSeek(xFilial("ZK1")+Subs(SE1->E1_HIST,14,6))
      MOMS68AS()
   EndIf

EndIf

SE1->(FWRestArea(_aAreaSE1))

Return


/*
===============================================================================================================================
Programa----------: MOMS68AS
Autor-------------: Igor Melgaco
Data da Criacao---: 08/01/2024
===============================================================================================================================
Descrição---------: Atualização do Status de Compensação dos Contratos
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS68AS() As Logical
Local _nSaldo  := 0 As Numeric
Local _cStatus := "" As Char
Local _cFilial := "92" As Char
Local _cTipoNCC := "NCC" As Char
Local _cPrefixo := "VRB" As Char
Local _lSE1 := .F. As Logical

   _cStatus :=  ZK1->ZK1_STATUS

   DBSelectArea("ZK3")
   ZK3->(DBSetOrder(1))
   If ZK3->(DBSeek(xFilial("ZK3")+ZK1->ZK1_CODIGO ))
      While xFilial("ZK3")+ZK1->ZK1_CODIGO == ZK3->ZK3_FILIAL+ZK3->ZK3_CODIGO .And. !ZK3->(Eof())

         If !Empty(Val(ZK3->ZK3_PARCEL))
            _cParcela := Val(ZK3->ZK3_PARCEL)
            _cParcela := StrZero(_cParcela,Len(SE1->E1_PARCELA)) 
         Else
            _cParcela := Space(Len(SE1->E1_PARCELA))
         EndIf

         cChave := StrZero(Val(AllTrim(ZK3->ZK3_CONTRA)),Len(SE1->E1_NUM))//AVKEY(ZK1->ZK1_CODIGO,"E1_NUM")

         SE1->( DBSetOrder(2) )
         //E1_FILIAL+E1_CLIENTE   +E1_LOJA        +E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
         If SE1->(DBSeek(_cFilial+ZK3->ZK3_FAVORE+ZK3->ZK3_FAVLOJ+_cPrefixo +cChave+_cParcela +_cTipoNCC))

            _nSaldo += SE1->E1_SALDO
            _lSE1 := .T.

         EndIf

         If _nSaldo > 0
            Exit
         EndIf
      
         ZK3->(DBSkip())
      EndDo

      If _nSaldo <= 0
         If _lSE1
            _cStatus := "6"
         Else
            _cStatus := IIf(_cStatus == "6","1", _cStatus) 
         EndIf
      Else
         _cStatus := IIf(_cStatus == "6","2", _cStatus)
      EndIf

      If _cStatus <> ZK1->ZK1_STATUS
         DBSelectArea("ZK1")
         ZK1->(RecLock("ZK1", .F.))      
         ZK1->ZK1_STATUS := _cStatus
         ZK1->(MSUnLock())
      EndIf

   EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS68AT
Autor-------------: Igor Melgaco
Data da Criacao---: 08/01/2024
===============================================================================================================================
Descrição---------: Reprocessamento do Status de Compensação dos Contratos
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS68AT(oproc As Object) As Logical

   DBSelectArea("ZK1")
   DBSetOrder(1)
   DBGoTop()
   While ZK1->(!Eof())
      If oproc <> Nil
         oproc:cCaption := ("Reprocessando Status do contrato "+ZK1->ZK1_CODIGO+".") 
      EndIf
      MOMS68AS()
      ZK1->(DBSkip())
   EndDo

Return

/*
===============================================================================================================================
Programa----------: MOMS068D
Autor-------------: Igor Melgaco
Data da Criacao---: 06/03/2024
===============================================================================================================================
Descrição---------: Gerar de Parcelas por Contrato
===============================================================================================================================
Parametros--------: oMsMGet,_aLinhas
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS068D(oMsMGet As Object) As Logical
Local oDlg     := Nil As Object
Local _lOk     := .F. As Logical
Local _aProd   := {} As Array
Local aLinha   := {} As Array
Local i        := 0 As Numeric
Local z        := 0 As Numeric
Local _aLinhas := oMsMGet:aCols As Array
Local cLinhaOk := "U_MOMS068E()" As Char
Local cTudoOk  := "U_MOMS068E()" As Char
Local cTitulo  := "Gerar de Parcelas por Contrato" As Char
Local _nValorParc  := 0 As Numeric
Local _nSomaParc := 0 As Numeric

Private oMsMGet2 := Nil As Object
Private aHeaderPar := {} As Array
Private aParcCont  := {} As Array

If Empty(AllTrim(M->ZK1_FAVORE))
   U_ITMsg("Falta de preenchimento de campo.","Atenção","Preencha o campo Favorecido antes de continuar",1)
Else
   aAdd(aHeaderPar,{"Contrato"               ,"ZK3_CONTRA","999999999"            ,09,0,"","","C","","","","",".T."})//01 
   aAdd(aHeaderPar,{"Numero de Parcelas"     ,"ZK3_VALOR" ,"@E 999,999,999,999",15,2,"","","N","","","","",".T."})//02
   aAdd(aHeaderPar,{"1° Vencimento"          ,"ZK3_VENCTO","@D"                   ,08,0,"","","D","","","","",".T."})//03
   aAdd(aHeaderPar,{"Intervalo de Dias"      ,"ZK3_VALOR" ,"@E 999,999,999,999",15,2,"","","N","","","","",".T."})//04
   aAdd(aHeaderPar,{"Valor de Contrato"      ,"ZK3_VALOR" ,"@E 999,999,999,999.99",15,2,"","","N","","","","",".T."})//04
     
   aLinha := {Space(9),0,CTOD(""),0,0,.F.}

   aAdd(aParcCont,aLinha)

   nGDAction:= (GD_INSERT+ GD_UPDATE + GD_DELETE) //  

   DEFINE DIALOG oDlg Title cTitulo PIXEL FROM 0,0 TO 400,800

      DEFINE SBUTTON FROM 004,370 Type 1 ENABLE ACTION ( IIf(U_MOMS068E(),(_lOk := .T. , oDlg:End()),Nil) ) OF oDlg
      DEFINE SBUTTON FROM 021,370 Type 2 ENABLE ACTION ( _lOk := .F.  , oDlg:End() ) OF oDlg

      ///***********************  MSNEWGETDADOS() ************************* ZK3
                                 //[ nTop], [ nLeft]   , [ nBottom] , [ nRight ] , [ nStyle],cLinhaOk,cTudoOk,cIniCpos, [ aAlter], [ nFreeze], [ nMax], [ cFieldOk], [ cSuperDel], [ cDelOk], [ oWnd], [ aPartHeader], [ aParCols], [ uChange], [ cTela], [ aColsSize] 
      oMsMGet2 := MsNewGetDados():New(50   ,0          ,200         ,400         ,nGDAction ,cLinhaOk ,cTudoOk,       ,          ,           ,        ,            ,             ,          ,oDlg    ,aHeaderPar        , aParcCont      ,           ,         , )

   ACTIVATE DIALOG oDlg CENTERED // ON INIT (EnchoiceBar(oDlg2,_bEfetivar,_bSair,,aBotoes) )//,;//oPnlTop:Align := CONTROL_ALIGN_TOP,;oMsMGet:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT )

   If _lOk
      aParcCont := oMsMGet2:aCols
      If !Empty(AllTrim(aParcCont[1,1]))
         If Empty(AllTrim(_aLinhas[1,1]))
            _aLinhas := {}
         EndIf
         
         For i := 1 to Len(aParcCont)
            _nSomaParc := 0
            For z := 1 To aParcCont[i,2]
               
               dVencto := aParcCont[i,3] + ( (z-1) * aParcCont[i,4])
               cParc := StrZero(z,2)
               _aProd := {}
               _nValorParc := Round(NoRound(aParcCont[i,5]/aParcCont[i,2],3),2)
               _nSomaParc += _nValorParc

               If z = aParcCont[i,2]
                  _nValorParc += aParcCont[i,5] - _nSomaParc
               EndIf

               aAdd(_aProd,aParcCont[i,1])//01 ZK3_CONTRA
               aAdd(_aProd,cParc)//02 ZK3_PARCEL
               aAdd(_aProd,_nValorParc )//03 ZK3_VALOR
               aAdd(_aProd,dVencto)//04 ZK3_VENCTO
               aAdd(_aProd,Space(Len(aParcCont[i,1])))//05  ZK3_TITULO    
               aAdd(_aProd,cParc)//06 ZK3_TITPAR
               aAdd(_aProd,M->ZK1_FAVORE)//07 ZK3_FAVORE
               aAdd(_aProd,M->ZK1_FAVLOJ)//08 ZK3_FAVLOJ
               aAdd(_aProd,M->ZK1_FAVDES)//09 ZK3_FAVDES
               aAdd(_aProd,0) //10 Recno
               aAdd(_aProd,.F. )//11 Delete

               aAdd(_aLinhas,_aProd )
               
            Next
         Next

         oMsMGet:aCols := _aLinhas
         oMsMGet:Refresh()
      EndIf
   EndIf
EndIf
Return


/*
===============================================================================================================================
Programa----------: MOMS068E
Autor-------------: Igor Melgaco
Data da Criacao---: 06/03/2024
===============================================================================================================================
Descrição---------: Gerar de Parcelas por Contrato
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS068E() As Logical
Local n          := oMsMGet2:oBrowse:nAt As Numeric
Local nPosContra := 1 As Numeric
Local nPosNumPar := 2 As Numeric
Local nPosVenc   := 3 As Numeric
Local nPosIntDia := 4 As Numeric
Local nPosVrCont := 5 As Numeric
Local _lRet      := .T. As Logical
Local aPar       := oMsMGet2:aCols As Array

If Empty(AllTrim(aPar[n,nPosContra]))
   _lRet := .F.
   _cMsg := "Contrato"
ElseIf aPar[n,nPosNumPar] <= 0
   _lRet := .F.
   _cMsg := "Nr de Parcelas"
ElseIf Empty(AllTrim(DToS(aPar[n,nPosVenc])))
   _lRet := .F.
   _cMsg := "1° Vencimento"
ElseIf aPar[n,nPosIntDia] <= 0
   _lRet := .F.
   _cMsg := "Intervalo de dias"
ElseIf aPar[n,nPosVrCont] <= 0
   _lRet := .F.
   _cMsg := "Valor de Contrato"
EndIf

If !_lRet
   U_ITMsg("Falta de preenchimento de campo.","Atenção","Preencha o campo "+_cMsg+" antes de continuar",1)
EndIf
	
Return _lRet



/*
===============================================================================================================================
Programa----------: MOMS068F
Autor-------------: Igor Melgaco
Data da Criacao---: 06/03/2024
===============================================================================================================================
Descrição---------: WorkFlow para notificação do Vendedor
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS068F(cVerba As Char, oMsMGet As Object, cDescCli As Char, cDescVend As Char, cEmail As Char) As Logical
Local cHtml      := "" As Char
Local cTo        := "" As Char
Local cGetCco    := "" As Char
Local cFrom      := "" As Char
Local cFilePrint := "" As Char
Local lRet       := .F. As Logical
Local _cAssunto  := "" As Char
Local _aConfig   := U_ITCFGEML(' ') As Array
Local _cLog      := "" As Char
Local _aContratos := oMsMGet:aCols As Array
Local _nTotal    := 0 As Numeric
Local i          := 0 As Numeric
Local _lContinua := .F. As Logical
Local _nColExc   := 0 As Numeric
Local _cGetSup   := U_ItGetMv("IT_MOMS68S", "sistema@italac.com.br") As Char
Local _cVendedor := "" As Char
Local _cEmailVend := "" As Char
Local _cSup      := "" As Char
Local _cEmailSup := "" As Char
Local _cCood     := "" As Char
Local _cEmailCood := "" As Char
Local _cGer      := "" As Char
Local _cEmailGer := "" As Char

   _aContratos:=aSort(_aContratos,,,{|x, y| x[1]+x[2] < y[1]+y[2]})

   If Len(_aContratos) > 0
      _nColExc := Len(_aContratos[1])
      For i := 1 To Len(_aContratos)
         If !_aContratos[i][_nColExc] 
            _lContinua := .T.
         EndIf
      Next
   EndIf

   If _lContinua
      cHtml := 'Prezado '+IIf(ZK1_ABATIM=="2",cDescVend, "Antonio ")+','
      cHtml += '<br><br>'
      cHtml += '<br><br>'
      cHtml += '&nbsp;&nbsp;&nbsp;Verba N. '+cVerba+' / Cliente: '+AllTrim(cDescCli)+' está liberada para '+ IIf(ZK1_ABATIM=="2","abatimento.","compensação") '
      cHtml += '<br><br>'
      cHtml += '<br><br>'

      For i := 1 to Len(_aContratos)
         If !_aContratos[i][_nColExc] 
            cHtml += '&nbsp;&nbsp;&nbsp;Contrato '+_aContratos[i,1]+IIf(Empty(AllTrim(_aContratos[i,2])),'',' / Parcela: '+_aContratos[i,2])+' / Valor: '+Transform(_aContratos[i,3],"@E 9,999,999,999.99") + " / Vencto: " + DToC(_aContratos[i,4])
            cHtml += '<br><br>'
            _nTotal += _aContratos[i,3]
         EndIf
      Next

      cHtml += '<br><br>'
      cHtml += '&nbsp;&nbsp;&nbsp;'+IIf(ZK1->ZK1_ABATIM=="2","Favor indicar número da Nota Fiscal conforme vencimento informado.","EXCLUIR")'
      cHtml += '<br><br>'

      cHtml += '<br><br>'
      cHtml += '&nbsp;&nbsp;&nbsp;A disposição!'
      cHtml += '<br><br>'
      cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
      cHtml += '<tr>'
      cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
      cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
      cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ "Contas a receber" +'</span></b>'
      cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
      cHtml +=     '</td>'
      cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
      cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
      cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
      cHtml +=              '<tr>'
      cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
      cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + "Depto Financeiro" + '</span></b>'
      cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
      cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
      cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
      cHtml +=                  '</td>'
      cHtml +=              '</tr>'
      cHtml +=         '</table>'
      cHtml +=     '</td>'
      cHtml += '</tr>'
      cHtml += '</table>'
      cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
      cHtml +=     '<tr>'
      cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
      cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
      cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
      cHtml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
      cHtml +=             '</span>
      cHtml +=             '</p>'
      cHtml +=         '</td>'
      cHtml +=     '</tr>'
      cHtml += '</table>'
      cHtml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
      cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
      cHtml +=     '<tr>'
      cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
      cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
      cHtml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
      cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
      cHtml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justify">'
      cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
      cHtml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
      cHtml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notificado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
      cHtml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
      cHtml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
      cHtml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
      cHtml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
      cHtml += '<BR>Ambiente: ['+ GETENVSERVER() +'] / Fonte: [RFIN002] </BR>'
      cHtml +=             '</span>'
      cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
      cHtml +=         '</td>'
      cHtml +=     '</tr>
      cHtml += '</table>'

      cGetCco := "" //cEmailVend

      _cVendedor  := Posicione("SA1",1,xFilial("SA1")+M->ZK1_FAVORE+AllTrim(M->ZK1_FAVLOJ),"A1_VEND") 
   	_cEmailVend := AllTrim(Posicione("SA3",1,xFilial("SA3")+_cVendedor,"A3_EMAIL"))

      _cSup       := Posicione("SA3",1,xFilial("SA3")+_cVendedor,"A3_I_SUPE")

      If Empty(AllTrim(_cSup))
         _cEmailSup  := ""
      Else
         _cEmailSup  := AllTrim(Posicione("SA3",1,xFilial("SA3")+_cSup,"A3_EMAIL"))
      EndIf

      _cCood := Posicione("SA3",1,xFilial("SA3")+_cVendedor,"A3_SUPER")
      
      If Empty(AllTrim(_cCood))
         _cEmailCood  := ""
      Else
         _cEmailCood  := AllTrim(Posicione("SA3",1,xFilial("SA3")+_cCood,"A3_EMAIL"))
      EndIf

      _cGer  := Posicione("SA3",1,xFilial("SA3")+_cVendedor,"A3_GEREN")
      
      If Empty(AllTrim(_cGer))
         _cEmailGer  := ""
      Else
         _cEmailGer  := AllTrim(Posicione("SA3",1,xFilial("SA3")+_cGer,"A3_EMAIL"))
      EndIf

      cTo := MOMS068FM(cTo,{_cEmailSup,_cEmailCood,_cEmailGer})    

      If Subs(M->ZK1_ABATIM,1,1) = "1"
         cTo := _cGetSup + ";" + cTo
      EndIf

      cFrom := SuperGetMV("IT_MOMS068",.F.,'sistema@italac.com.br') 
      cGetCco := cFrom

      cFilePrint := ""
      
      _cAssunto := "VERBA LIBERADA PARA "+IIf(ZK1_ABATIM=="2"," ABATIMENTO "," COMPENSACAO ") + AllTrim(cDescCli) + " Valor " + AllTrim(Transform(_nTotal,"@E 9,999,999,999.99"))  

      U_ITENVMAIL( cFrom , cTo ,  ,cGetCco  , _cAssunto , cHtml , cFilePrint , _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cLog )
      
      lRet :=  ("Sucesso" $ _cLog)
      
      U_ItMsg(IIf(lRet,"Email enviado com sucesso para "+cTo+"!","Falha no Envio do email: "+_cLog),"Atenção",,IIf(lRet,2,1))
   EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS068FM
Autor-------------: Igor Melgaco
Data da Criacao---: 28/08/2024
===============================================================================================================================
Descrição---------: Formata o campo Para de email a ser enviado
===============================================================================================================================
Parametros--------: cTo,vEmail
===============================================================================================================================
Retorno-----------: cTo
===============================================================================================================================
*/
Static Function MOMS068FM(cTo As Char, vEmail ) As Char
Local i := 0 As Numeric 

If ValType(vEmail) == "A"
   For i:= 1 To Len(vEmail)
      cTo := MOMS068FE(cTo,vEmail[i])  
   Next
Else
   cTo := MOMS068FE(cTo,vEmail)  
EndIf

Return cTo


/*
===============================================================================================================================
Programa----------: MOMS068FE
Autor-------------: Igor Melgaco
Data da Criacao---: 28/08/2024
===============================================================================================================================
Descrição---------: Formata o campo Para de email a ser enviado evitando dulpicidade
===============================================================================================================================
Parametros--------: cTo,cEmail
===============================================================================================================================
Retorno-----------: cTo
===============================================================================================================================
*/
Static Function MOMS068FE(cTo As Char, cEmail As Char) As Char
Local aEmail := {} As Array
Local i := 0 As Numeric

If !Empty(AllTrim(cEmail)) 
   cEmail := StrTran(cEmail,",",";")

   If ";" $ cEmail
      aEmail := StrToArray(cEmail,";")
      For i := 1 To Len(aEmail)
         If !Empty(AllTrim(aEmail[i])) .And. !(aEmail[i] $ cTo)
            cTo += ";" + aEmail[i]
         EndIf
      Next
   Else
      If !(cEmail $ cTo)
         cTo += ";" + cEmail
      EndIf
   EndIf
EndIf

Return cTo

/*
===============================================================================================================================
Programa----------: MOMS068ET
Autor-------------: Igor Melgaco
Data da Criacao---: 28/08/2024
===============================================================================================================================
Descrição---------: Edita o campo de valor do Rateio
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/
Static Function MOMS068ET(_aProdutos As Array, _oListProd As Object, nPos As Numeric, oEnCh1 As Object) As Logical
Local _nI  := 0 As Numeric
Local _nTotal := 0 As Numeric 
 
_aProdutos[_oListProd:nAt,nPos] := Val(_aProdutos[_oListProd:nAt,nPos])

lEditCell(_aProdutos,_oListProd,"@E 99,999,999,999.99",nPos)

_aProdutos[_oListProd:nAt,nPos] := Transform(_aProdutos[_oListProd:nAt,nPos],"@E 99,999,999,999.99")
_aProdutos[_oListProd:nAt,n2PosVRFAM] :=_aProdutos[_oListProd:nAt,nPos] 

For _nI := 1 To Len(_aProdutos)
   _nTotal += Val(StrTran(StrTran(_aProdutos[_nI][nPos],".",""),",","."))
Next

M->ZK1_VLRCOR := _nTotal

oEnCh1:Refresh()

Return


/*
===============================================================================================================================
Programa----------: MOMS068VI
Autor-------------: Igor Melgaco
Data da Criacao---: 08/04/2025
===============================================================================================================================
Descrição---------: Verifica se valida Vendedor, Coordenador e Gerente pelo cliente ou pela Rede
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/
Static Function MOMS068VI() As Logical
Local _lRet   := .T. As Logical
Local _cQuery := "" As Char
Local _cAlias := GetNextAlias() As Char
Local _lVen   := .F. As Logical
Local _lCoord := .F. As Logical
Local _lGer   := .F. As Logical

   If !Empty(AllTrim(MV_PAR04))
      _cQuery := "SELECT A1_COD , A1_LOJA , A1_NOME , A1_NREDUZ , A1_CGC "
      _cQuery += " FROM "+RetSqlName("SA1")+" SA1 "
      _cQuery += "   LEFT JOIN " + RetSqlName("SA3") + " SA3   ON SA1.A1_VEND    = SA3.A3_COD   AND SA3.D_E_L_E_T_   = ' ' " 
      _cQuery += " WHERE A1_MSBLQL <> '1' "
      _cQuery += "   AND SA1.D_E_L_E_T_ = ' ' "
      _cQuery += "   AND A1_GRPVEN = '" + MV_PAR04 + "'"
      _cQuery += " GROUP BY A1_COD , A1_LOJA , A1_NOME , A1_NREDUZ , A1_CGC "
      _cQuery += " ORDER BY A1_COD, A1_LOJA "
      _cQuery := ChangeQuery(_cQuery)

      MPSysOpenQuery( _cQuery , _cAlias)

      (_cAlias)->(DBGoTop())
      While (_cAlias)->(!Eof())
         lRet := MOMS068VC((_cAlias)->A1_COD,(_cAlias)->A1_LOJA,@_lVen,@_lCoord,@_lGer)
         If !lRet
            Exit
         EndIf
         (_cAlias)->(DBSkip())
      EndDo

   ElseIf !Empty(AllTrim(MV_PAR05))
      _lRet := MOMS068VC(MV_PAR05,MV_PAR06,@_lVen,@_lCoord,@_lGer)
   EndIf

   If _lRet
      If !_lVen
         U_ITMsg("O Vendedor preenchido não consta como vendedor deste Cliente.",'Atenção!',"",3)
         _lRet := .F.
      ElseIf !_lCoord
         U_ITMsg("O Coordenador preenchido não consta como Coordenador dos Vendedores deste Cliente.",'Atenção!',"",3)
         _lRet := .F.
      ElseIf !_lGer
         U_ITMsg("O Gerente preenchido não consta como Gerente dos Vendedores deste Cliente.",'Atenção!',"",3)
         _lRet := .F.
      EndIf
   EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS068VC
Autor-------------: Igor Melgaco
Data da Criacao---: 08/04/2025
===============================================================================================================================
Descrição---------: Verifica se Vendedor, Coordenador e Gerente pertence ao Cliente
===============================================================================================================================
Parametros--------: _CodCli, _cLoja, _lVen, _lCoord, _lGer                              
===============================================================================================================================
Retorno-----------: _lRet
===============================================================================================================================
*/
Static Function MOMS068VC(_CodCli As Char,_cLoja As Char,_lVen As Logical,_lCoord As Logical,_lGer As Logical) As Logical
Local _lRet   := .T. As Logical
Local _cVend  := "" As Char
Local _cCoord := "" As Char
Local _cGer   := "" As Char
Local _cMsg   := "" As Char

   If !Empty(AllTrim(_CodCli))

      If Empty(AllTrim(_cLoja))
         cExpressao := "xFilial('SA1')+SA1->A1_COD == xFilial('SA1')+_CodCli"
      Else
         cExpressao := "xFilial('SA1')+SA1->A1_COD+SA1->A1_LOJA == xFilial('SA1')+_CodCli+_cLoja"
      EndIf        

      DBSelectArea("SA1")
      DBSetOrder(1)
      If SA1->(DBSeek(xFilial("SA1")+_CodCli+AllTrim(_cLoja)))
         While &cExpressao .And. !SA1->(Eof())
            DBSelectArea("SA3")
            DBSetOrder(1)
            If SA3->(DBSeek(xFilial("SA3")+SA1->A1_VEND))
               _cVend  += IIf(SA3->A3_COD $_cVend  ,"", "|" + SA3->A3_COD)
               _cCoord += IIf(SA3->A3_I_SUPE $_cCoord,"", "|" + SA3->A3_I_SUPE)
               _cGer   += IIf(SA3->A3_GEREN $_cGer ,"", "|" + SA3->A3_GEREN)
               _cMsg   := "" 

               If !Empty(MV_PAR09) .And. SA3->A3_COD == MV_PAR09  

                  _lVen := .T. // O Vendedor Pertence a uma das Lojas
                  _cMsg := ""
                  If !Empty(MV_PAR08) .And. SA3->A3_I_SUPE <> MV_PAR08 
                     _cMsg :=  "O Coordenador preenchido não consta como Coordenador deste Vendedor "+MV_PAR09
                  EndIf

                  If !Empty(MV_PAR07) .And. SA3->A3_GEREN <> MV_PAR07 
                     If Empty(AllTrim(_cMsg))
                        _cMsg := "O Gerente preenchido não consta como Gerente deste Vendedor "+MV_PAR09
                     Else
                        _cMsg := "O Coordenador e o Gerente preenchido não constam como Coordenador e Gerente deste Vendedor "+MV_PAR09
                     EndIf
                  EndIf    

                  If !Empty(AllTrim(_cMsg))
                     U_ITMsg(_cMsg,'Atenção!',"",3)
                     _lRet := .F.
                     Exit
                  EndIf
               EndIf
               If !Empty(MV_PAR08) .And. SA3->A3_I_SUPE == MV_PAR08 
                  _lCoord := .T.
               EndIf
               If !Empty(MV_PAR07) .And. SA3->A3_GEREN == MV_PAR07 
                  _lGer := .T.
               EndIf
            
            EndIf
            SA1->(DBSkip())
         EndDo
      EndIf

   EndIf

   If Empty(MV_PAR09) 
      _lVen := .T.
   EndIf

   If Empty(MV_PAR08) 
      _lCoord := .T.
   EndIf

   If Empty(MV_PAR07)
      _lGer := .T.
   EndIf

Return _lRet
