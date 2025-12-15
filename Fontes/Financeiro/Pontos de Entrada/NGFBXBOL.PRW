//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include 'Protheus.ch'

/*
===============================================================================================================================
Programa----------: NGFBXBOL
Autor-------------: Igor Melgaço
Data da Criacao---: 22/09/2025
===============================================================================================================================
Descrição---------: Ponto de Entrada de Processamento de Download de Arquivo do Boleto
                   - Realiza o download do arquivo do boleto gerado pelo Protheus.
                   - O arquivo é baixado com o nome personalizado pelo cliente.
                   - Se o arquivo não for gerado pela aplicação, busca na tabela SE1.
                   - Retorna o caminho e nome do arquivo baixado.
                   - Utiliza a tabela SEA para obter informações do título. 
                     Chamado 51754
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function NGFBXBOLXX() As Array
 
    Local aAreaSEA  As Array
    Local aRet      As Array
    Local nRecSEA   As Numeric
    Local lArqGer   As Logical
    Local cNomeArq  As Character
    Local cNomeBx   As Character  
 
    aAreaSEA    := GetArea('SEA')
    aRet        := {}
    nRecSEA     := PARAMIXB[1][1][1] // RECNO da tabela SEA
    lArqGer     := PARAMIXB[1][1][2] // Se .T. arquivo gerado por nossa aplicação. Se .F. Variavel nome do arquivo estará vazia.
    cNomeArq    := PARAMIXB[2]       // Arquivo gerado "\spool\NOMEDOARQUIVO.pdf"
    cNomeBx     := PARAMIXB[3]       // Chave do título (Prefixo + Numero + Parcela + Tipo.pdf"   DbSelectArea("SEA")
 
    SEA->(DbGoTo(nRecSEA))
 
    DbSelectArea("SE1")
    DbSetOrder(1)
    If SE1->(DbSeek(SEA->EA_FILIAL + SEA->EA_PREFIXO + SEA->EA_NUM + SEA->EA_PARCELA + SEA->EA_TIPO))
        cFilAnt := SE1->E1_FILIAL
        cNomeArq := U_RFIN002P()
    EndIf
    cDetalhe := "Download do arquivo do boleto: " + cNomeArq
    U_ITGrvAce("BOLETO",cDetalhe)
    Aadd(aRet, {cNomeArq, cNomeBx} )

    RestArea(aAreaSEA)
 
Return aRet
