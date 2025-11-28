/*
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                              Motivo                                                          |
-------------------------------------------------------------------------------------------------------------------------------
=============================================================================================================================== 
*/
#Include "TOTVS.ch"
/*
===============================================================================================================================
Programa----------: AOMS102
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 20/04/2017
===============================================================================================================================
Descrição---------: Rotina de manutenção no cadastro de Regras de Bloqueio de Geração de PV - Chamado: 19585
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/  
User Function AOMS102()

aRotina := {{ OemToAnsi("Pesquisar")  , "AxPesqui"   , 0 , 1 },; 
            { OemToAnsi("Visualizar") , 'AxVisual'   , 0 , 2 },; 
            { OemToAnsi("Incluir")    , 'U_AOMS102I' , 0 , 3 },; 
            { OemToAnsi("Alterar")    , 'U_AOMS102A' , 0 , 4 },; 
            { OemToAnsi("Excluir")    , 'AxDeleta'   , 0 , 5 } } 

cCadastro := OemToAnsi( "Cadastro de Regras de Bloqueio de Geração de PV" )

MBrowse( ,,,, "ZBP" )

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS102I
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 20/04/2017
===============================================================================================================================
Descrição---------: Chama AxInclui()  com a validação "U_AOMS102V()"
===============================================================================================================================
Parametros--------: cAlias,nReg,nOpc
===============================================================================================================================
Retorno-----------: AxInclui()
===============================================================================================================================
*/  
User Function AOMS102I(cAlias,nReg,nOpc) 
Return AxInclui(cAlias,nReg,nOpc,,,,"U_AOMS102V()")

/*
===============================================================================================================================
Programa----------: AOMS102C
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 20/04/2017
===============================================================================================================================
Descrição---------: Chama AxAltera() com a validação "U_AOMS102V()"
===============================================================================================================================
Parametros--------: cAlias,nReg,nOpc
===============================================================================================================================
Retorno-----------: AxAltera()
===============================================================================================================================
*/  
User Function AOMS102A(cAlias,nReg,nOpc) 
Return AxAltera(cAlias,nReg,nOpc,,,,,"U_AOMS102V()")

/*
===============================================================================================================================
Programa----------: AOMS102V
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 20/04/2017
===============================================================================================================================
Descrição---------: Validar a digitação dos dados no Cadastro
===============================================================================================================================
Parametros--------: NIL
===============================================================================================================================
Retorno-----------: True ou False
===============================================================================================================================
*/  
User Function AOMS102V()
Local _lRet := .T.   
Local _cChaveAtual:= ZBP->ZBP_FILIAL+ZBP->ZBP_OPERAC+ZBP->ZBP_ESTADO+ZBP->ZBP_CODMUN+ZBP->ZBP_TIPCLI+ZBP->ZBP_CLIENT+ZBP->ZBP_CLILOJ+ZBP->ZBP_GRUPO+ZBP->ZBP_NCM+ZBP->ZBP_PRODUT
Local _nRecAtual  := ZBP->(RECNO())

If Empty(M->ZBP_OPERAC+M->ZBP_ESTADO+M->ZBP_CODMUN+M->ZBP_TIPCLI+M->ZBP_CLIENT+M->ZBP_GRUPO+M->ZBP_NCM+M->ZBP_PRODUT )
   xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"Regra de bloqueio não preenchida.","Preencha pelo um dos Campos: Estado, Municipio, Tipo do Cliente, Código do Cliente, Grupo, NCM ou Produto.")
   Return .F.
EndIf   

ZBP->(DBSetOrder(1))
If Inclui .Or. _cChaveAtual # xFilial()+M->ZBP_OPERAC+M->ZBP_ESTADO+M->ZBP_CODMUN+M->ZBP_TIPCLI+M->ZBP_CLIENT+M->ZBP_CLILOJ+M->ZBP_GRUPO+M->ZBP_NCM+M->ZBP_PRODUT//Esse teste é por causa da alteração para não acha ele mesmo caso o usuario não tenha alterado nada
   If ZBP->(DBSeek( xFilial()+M->ZBP_OPERAC+M->ZBP_ESTADO+M->ZBP_CODMUN+M->ZBP_TIPCLI+M->ZBP_CLIENT+M->ZBP_CLILOJ+M->ZBP_GRUPO+M->ZBP_NCM+M->ZBP_PRODUT ))
      xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"Regra de bloqueio já cadastrada.","Preencha ou apague mais um campo para diferenciar da regra atual.")
      ZBP->(DBGoTo(_nRecAtual))//Por causa da alteração
      Return .F.
   EndIf   
EndIf   
ZBP->(DBGoTo(_nRecAtual))//Por causa da alteração

SA1->(DBSetOrder(1))
//Estado -> Municipio -> Tipo de Cliente 
If !Empty(M->ZBP_CLIENT) .And. !Empty(M->ZBP_CLILOJ) .And.  SA1->(DBSeek( xFilial("SA1")+M->ZBP_CLIENT+M->ZBP_CLILOJ ))
 
   _cEstado   :=SA1->A1_EST
   _cMunicipio:=SA1->A1_COD_MUN
   _cTpCliente:=SA1->A1_TIPO

   If !Empty(M->ZBP_ESTADO) .And. M->ZBP_ESTADO # _cEstado
      xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"Estado difere do cadastro do cliente: "+_cEstado,"Apague o campo do estado ou do cliente + loja")
      Return .F.
   EndIf

   If !Empty(M->ZBP_CODMUN) .And. M->ZBP_CODMUN # _cMunicipio 
      xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"Municipio difere do cadastro do cliente: "+_cMunicipio,"Apague o campo do Municipio ou do cliente + loja")
      Return .F.
   EndIf

   CC2->(DBSetOrder(1))
   If !Empty(M->ZBP_ESTADO) .And. !Empty(M->ZBP_CODMUN) .And. !CC2->(DBSeek( xFilial("CC2")+M->ZBP_ESTADO+M->ZBP_CODMUN ))
      xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"Municipio não pertence a esse estado.","Apague o campo do Municipio ou estado")
      Return .F.
   EndIf

   If !Empty(M->ZBP_TIPCLI) .And. M->ZBP_TIPCLI # _cTpCliente
      xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"Tipo do cliente difere do cadastro do cliente: "+_cTpCliente,"Apague o campo do Tipo do cliente ou do cliente + loja")
      Return .F.
   EndIf
ElseIf Empty(M->ZBP_CLIENT) .And. !Empty(M->ZBP_CLILOJ)

   xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"Loja do cliente preenchida sem o codigo do cliente.","Apague a loja do cliente.")
   Return .F.

EndIf

SB1->(DBSetOrder(1))
//Grupo de Produto -> NCM
If !Empty(M->ZBP_PRODUT) .And. SB1->(DBSeek( xFilial("SB1")+M->ZBP_PRODUT ))

   _cGrupo:=SB1->B1_GRUPO
   _cNCM  :=SB1->B1_POSIPI

   If !Empty(M->ZBP_GRUPO) .And. M->ZBP_GRUPO # _cGrupo
      xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"Grupo difere do cadastro do produto: "+_cGrupo,"Apague o campo do grupo ou do produto")
      Return .F.
   EndIf

   If !Empty(M->ZBP_NCM)   .And. M->ZBP_NCM   # _cNCM
      xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"NCM difere do cadastro do produto: "+_cNCM,"Apague o campo do NCM ou do produto")
      Return .F.
   EndIf

EndIf

If !Empty(M->ZBP_ESTADO) .And. !Empty(M->ZBP_CODMUN) .And. !ExistCpo("CC2",M->ZBP_ESTADO+M->ZBP_CODMUN)
   Return .F.
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS102G
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 20/04/2017
===============================================================================================================================
Descrição---------: Gatilhos chamados do campo X3_VLDUSER
===============================================================================================================================
Parametros--------: NIL
===============================================================================================================================
Retorno-----------: True ou False
===============================================================================================================================
*/  
User Function AOMS102G(nCampo)//U_AOMS102G()

If nCampo = 1
   
   If Empty(M->ZBP_ESTADO) .And. !Empty(M->ZBP_CODMUN)
      xMagHelpFis('Atenção! (AOMS102-'+AllTrim(Str(ProcLine()))+')',"Estado não preenchido.","Para preencher o municipio dever ser preencher o estado.")
      Return .F.
   EndIf
   If !Empty(M->ZBP_ESTADO) .And. !Empty(M->ZBP_CODMUN) .And. ExistCpo("CC2",M->ZBP_ESTADO+M->ZBP_CODMUN)
      M->ZBP_DESMUN:=Posicione("CC2",1,xFilial("CC2")+M->ZBP_ESTADO+M->ZBP_CODMUN,"CC2_MUN")
   Else
      M->ZBP_DESMUN:=" "
   EndIf

ElseIf nCampo = 2

   M->ZBP_DESCLI:=Posicione("SA1",1,xFilial("SA1")+M->ZBP_CLIENT+AllTrim(M->ZBP_CLILOJ),"A1_NREDUZ")

ElseIf nCampo = 3

   M->ZBP_DESGRU:=Posicione("SBM",1,xFilial("SBM")+M->ZBP_GRUPO,"BM_DESC")

ElseIf nCampo = 4

   M->ZBP_DESPRO:=Posicione("SB1",1,xFilial("SB1")+M->ZBP_PRODUT,"B1_DESC")

EndIf

Return .T.
