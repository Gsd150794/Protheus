/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A650REVEM
Autor-------------: Alex Wallauer
Data da Criacao---: 18/12/2018
Descrição---------: Ponto de Entrada para alterar a Revisao da estrutura - Chamado 27300
Parametros--------: ParamIXB[1] = cRevAtu
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A650REVEM

Local _cSelectSG5:="SELECT G5_REVISAO,G5_OBS FROM "+RETSQLNAME("SG5")+" SB1 WHERE G5_PRODUTO = '"+SB1->B1_COD+"' AND G5_FILIAL = '"+xFilial('SG5')+"' AND  D_E_L_E_T_ = ' ' ORDER BY G5_REVISAO " 
Local _cTitAux:="PRODUTO: "+SB1->B1_COD+" - REVISOES"
Private _cRevAtu:=ParamIXB[1]
/*
Parametros-------:
01 _cNomeSXB-----: Opção Do Case               DEFAULT: 'F3_GENER'           Ex.: "F3_GENER"
02 _cTabela------: Nome da Tabela              DEFAULT: ''                   Ex.: "SA2" ou um "SELECT * FROM SA2010'"
03 _nCpoChave----: Posição do Campo Chave      DEFAULT: 2                    Ex.: SA2->(FIELDPOS("A2_COD")) ou {|| SA2->A2_COD+" "+SA2->A2_LOJA }
04 _nCpoDesc-----: Posição do Campo Descrição  DEFAULT: 3                    Ex.: SA2->(FIELDPOS("A2_NREDUZ")) ou {|| SA2->A2_NREDUZ }
05 _bCondTab-----: CodeBlock de Exceção        DEFAULT: {|| .T. }            Ex.: {|| SA3->A3_MSBLQL <> '1' }
06 _cTitAux------: Titulo da Janela            DEFAULT: ''                   Ex.: "Tipos de Informação"
07 _nTamChv------: Tamanho do Campo Chave      DEFAULT: 1                    Ex.: Len(SA2->A2_COD)
08 _aDados-------: Array com as descrições     DEFAULT: {}                   Ex.: Função que retorna uma array (_aDados) ou uma String: "V=VENDA;R=REMESSA;O=OUTROS"
09 _nMaxSel------: Quantidade de Seleção       DEFAULT: 0                    Ex.: Len(_aDados)
10 _lFilAtual----: Opção de ler as Filiais     DEFAULT: .T.                  Ex.: .T. : Le a Filial Atual , .F. : Le Todas as Filiais
11 _cMVRET-------: Nome do campo do ReadVar()  DEFAULT: AllTrim( ReadVar() ) Ex.: "MV_PAR01"
12 _bValida------: Executado antes da Tela     DEFAULT: {|| .T. }            Ex.: {|| If(Len(_aDados) > 0 , .T. , .F. ) }
13 _oProc--------: Obejeto do da função FWMsgRun()
14 _aParam-------: Array equivalente a array _aItalac_F3
================================================================================================================================================================================*/
//             1           2         3                           4                                      5       6         7           8          9         10           11        12        13       14
//ITF3GEN(_cNomeSXB , _cTabela  ,_nCpoChave                , _nCpoDesc                           , _bCondTab,_cTitAux, _nTamChv , _aDados , _nMaxSel , _lFilAtual , _cMVRET  , _bValida , _oProc , _aParam )
U_ITF3GEN('F3_GENER',_cSelectSG5,{|Tab| (Tab)->G5_REVISAO },{|Tab| StrTran((Tab)->G5_OBS,"-","")},          ,_cTitAux,    03    ,         ,  01      ,.F.         ,"_cRevAtu",  )
_cRevAtu:=_cRetorno

Return {_cRevAtu}
