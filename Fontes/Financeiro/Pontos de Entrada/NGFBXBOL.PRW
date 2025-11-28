/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |22/09/2025| Chamado 51754. Ponto de Entrada de Processamento de Download de Arquivo do Boleto
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: NGFBXBOL
Autor-------------: Igor Melgaço
Data da Criacao---: 22/09/2025
Descrição---------: Ponto de Entrada de Processamento de Download de Arquivo do Boleto
                   - Realiza o download do arquivo do boleto gerado pelo Protheus.
                   - O arquivo é baixado com o nome personalizado pelo cliente.
                   - Se o arquivo não For gerado pela aplicação, busca na tabela SE1.
                   - Retorna o caminho e nome do arquivo baixado.
                   - Utiliza a tabela SEA para obter informações do título. 
                     Chamado 51754
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function NGFBXBOL() As Array
 
Local aAreaSEA  As Array
Local aRet      As Array
Local nRecSEA   As Numeric
Local lArqGer   As Logical
Local cNomeArq  As Character
Local cNomeBx   As Character  

aAreaSEA    := GetArea('SEA')
aRet        := {}
nRecSEA     := ParamIXB[1][1][1] // RECNO da tabela SEA
lArqGer     := ParamIXB[1][1][2] // Se .T. arquivo gerado por nossa aplicação. Se .F. Variavel nome do arquivo estará vazia.
cNomeArq    := ParamIXB[2]       // Arquivo gerado "\spool\NOMEDOARQUIVO.pdf"
cNomeBx     := ParamIXB[3]       // Chave do título (Prefixo + Numero + Parcela + Tipo.pdf"   DBSelectArea("SEA")

SEA->(DBGoTo(nRecSEA))

DBSelectArea("SE1")
SE1->(DBSetOrder(1))
If SE1->(DBSeek(SEA->EA_FILIAL + SEA->EA_PREFIXO + SEA->EA_NUM + SEA->EA_PARCELA + SEA->EA_TIPO))
    cFilAnt := SE1->E1_FILIAL
    cNomeArq := U_RFIN002P()
EndIf

aAdd(aRet, {cNomeArq, cNomeBx} )

FWRestArea(aAreaSEA)
 
Return aRet
