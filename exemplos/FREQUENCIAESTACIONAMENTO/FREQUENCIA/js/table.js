function formatCol(tabela, db) {
    tabela.setAddInOptions("colType","formattedText",function(state){
       
       if(state.category == 'DIA DA SEMANA' || state.category == 'CLIENTE' || state.category == 'ORIGEM'  || state.category == 'BENEFÍCIO'  || state.category == 'PROMOÇÃO') {
            return {
                textFormat: function(v, st) {
                    if (v !== null && v !== '') {
                        return '<span data-toggle="tooltip" data-container="body" title="'+capitalize(v)+'">' + capitalize(v) + '</span>';
                    }
                    return '-';
                }
            }
        }
        else if(state.category == '% DO TOTAL') {
            return {
                textFormat: function(v, st) {
                    if (v !== null && v !== '') {
                        return numericBR(v, 2) + '%';
                    }
                    return '';
                }
            }
        }
        else if(state.category == 'MÉDIA') {
            return {
                textFormat: function(v, st) {
                    if (v !== null && v !== '') {
                        return numericBR(v, 2);
                    }
                    return '';
                }
            }
        }
        else if(state.category == 'ÚLTIMA FREQUÊNCIA' || state.category == 'DATA DE ENTRADA' || state.category == 'DATA DE SAÍDA') {
            return {
                textFormat: function(v, st) {
                    if (v !== null && v !== '') {
                        return Data.formatDtHr(v);
                    }
                    return '';
                }
            }
        } 
        else if(state.category == 'FREQUÊNCIA' && db == 'clientesFrequencia') {
            return {
                textFormat: function(v, st) {
                    if (v !== null && v !== '') {
                        return v.toLowerCase();
                    }
                    return '';
                }
            }
        } 
        else if(state.category == 'BAIRRO') {
            return {
                textFormat: function(v, st) {
                    if (v !== null && v !== '') {
                        var linha = v.toString().split('-');
                        var bairro = linha[0].trim();
                        return '<span data-toggle="tooltip" data-container="body" title="'+capitalize(v)+'">' + capitalize(bairro) + '</span>';
                    }
                    return '-';
                }
            }
        }
        else if(state.category == 'COMPRAS' || state.category == 'VALOR PAGO' || state.category == 'TOTAL') {
            return {
                textFormat: function(v, st) {
                    if (v !== null && v !== '') {
                        return 'R$' + numericBR(v, 2);
                    }
                    return '';
                }
            }
        }
        else if(state.category == 'COD') {
            return {
                textFormat: function(v, st) {
                    if (v && url()) {
                        var u = pURL.replace('CCenterWeb', '#!') + 'emp/' + pEmpreendimento + '/menu/atendimento_cliente/cliente/' + v + '/dashboard';
                        return '<div class="text-center" title="Dashboard do cliente"><a href="'+u+'" target="_blank" style="color: #1b2b38"><span class="glyphicon glyphicon-share-alt"></span></a></div>';
                    }
                    return '-';
                }
            };
        }
        else {
            return {
                textFormat: function(v, st) {
                    if (v !== null && v !== '') {
                        return numericBR(v, 0);
                    }
                    return '';
                }
            }
        }
    });
    
    var w;
    tabela.setAddInOptions("colType","dataBar",function(state){
        var colors = ['#3ab54b', '#8cc63e', '#8dc73f', '#8cc63c', '#8cc43f', '#dbdf26', '#d7e021', '#d9e021', '#d9e020', '#d6df20'];

        if(db == 'bairros') {
            if(!w) w = state.target[0].clientWidth;
            colors = ['#f8707a', '#fdae61', '#fdae61', '#fdae61', '#fdae61', '#fee08a', '#fee08a', '#fee08a', '#fee08a', '#ffdf8c'];
            return {
                width: w,
                widthRatio: 0.9,
                height: 10,
                startColor: colors[state.rowIdx].toString(),
                endColor: colors[state.rowIdx].toString()
            }
        }
        else {
            return {
                width: 120,
                widthRatio: 0.9,
                height: 10,
                startColor: colors[state.rowIdx].toString(),
                endColor: colors[state.rowIdx].toString()
            }
        }
    });
    
    tabela.setAddInOptions("colType","tvzBar",function(state){
        if(db == 'bairros') {
            return {
                color: '#f8707a'
            }
        }
        return {
            color: '#3ab54b'
        }
    });
}

function bsTable(tb, v) {
    $('#' + tb.htmlObject + 'Table').removeClass('table-striped table-bordered').addClass('table-condensed');
    if(v == 'clientes') {
        $('#' + tb.htmlObject + 'Table td').addClass('pointer');
        $('#' + tb.htmlObject + 'Table th.column1').text('');
        $('#' + tb.htmlObject + 'Table .column2').css('text-align', 'left');
        $('#' + tb.htmlObject + 'Table td.column2').addClass('ellipsis');
        $('#' + tb.htmlObject + 'Table .column4').css('text-align', 'left');
        $('#' + tb.htmlObject + 'Table td.column4').addClass('ellipsis');
        $('#' + tb.htmlObject + 'Table .column6').css('text-align', 'left');
        
        
        //$('#' + tb.htmlObject + 'Table .column5').css('text-align', 'right');
        //$('#' + tb.htmlObject + 'Table .column7').css('text-align', 'right');
        //$('#' + tb.htmlObject + 'Table .column8').css('text-align', 'right');
    }
    else if(v == 'lojas') {
        $('#' + tb.htmlObject + 'Table td').addClass('pointer');
        $('#' + tb.htmlObject + 'Table .column2').css('text-align', 'left');
        $('#' + tb.htmlObject + 'Table td.column2').addClass('ellipsis');
        $('#' + tb.htmlObject + 'Table .column3').css('white-space', 'nowrap');
        
        if(pOrdemLoja == 'VALOR') {
            $('#' + tb.htmlObject + 'Table th.column4').attr('data-priority', '2');
            $('#' + tb.htmlObject + 'Table th.column5').html('');
        }
        else if(pOrdemLoja == 'NOTAS') {
            $('#' + tb.htmlObject + 'Table th.column6').attr('data-priority', '2');
            $('#' + tb.htmlObject + 'Table th.column7').html('');
        }
        else {
            $('#' + tb.htmlObject + 'Table th.column8').attr('data-priority', '2');
            $('#' + tb.htmlObject + 'Table th.column9').html('');
        }
    }
    else if(v == 'bairros') {
        $('#' + tb.htmlObject + 'Table td').addClass('pointer');
        $('#' + tb.htmlObject + 'Table .column0').css('text-align', 'left');
        $('#' + tb.htmlObject + 'Table td.column0').addClass('ellipsis');
        $('#' + tb.htmlObject + 'Table th.column8').attr('data-priority', '2');
    }
    else if(v == 'faixaValores') {
        $('#' + tb.htmlObject + 'Table td').addClass('pointer');
        $('#' + tb.htmlObject + 'Table .column0').css('text-align', 'left');
        $('#' + tb.htmlObject + 'Table td.column0').addClass('ellipsis');
        $('#' + tb.htmlObject + 'Table th.column8').attr('data-priority', '2');
    }
    else if(v == 'diaSemana') {
        $('#' + tb.htmlObject + 'Table td').addClass('pointer');
        $('#' + tb.htmlObject + 'Table .column1').css('text-align', 'left');
    }
    else if(v == 'clientesFrequencia') {
        $('#' + tb.htmlObject + 'Table .column1').css('text-align', 'left');
    }    
    
}

function bsTableDetalhe(tb, v) {
    $('#' + tb.htmlObject + 'Table').removeClass('table-striped table-bordered').addClass('table-condensed table-detalhe');
    $('#' + tb.htmlObject + 'Table .column0').css('text-align', 'left');
    $('#' + tb.htmlObject + 'Table .column2').css('text-align', 'left');
}

function ftResponsive(col, value) {
    if(col == 'CLIENTE' || col == 'BAIRRO' || col == 'LOJA') {
        return capitalize(value);
    }
    else if(col == 'ÚLTIMA FREQUÊNCIA') {
        return value ? Data.formatDtHr(value) : '';
    }
    else if(col == 'CPF' || col == 'TEMPO' || col == 'MÉDIA') {
        return value;
    }
    return value ? numericBR(value, 0) : 0;
}

function responsive(tb, expand) {
    if(expand == 'n') {
        new $.fn.dataTable.Responsive($('#' + tb.htmlObject + 'Table'), {
            details: {
                renderer: function ( api, rowIdx, columns ) {
                    var data = $.map(columns, function(col, i) {
                        return col.hidden ? '<tr data-dt-row="'+col.rowIndex+'" data-dt-column="'+col.columnIndex+'">'
                        + '<td class="dtr-titulo">' + col.title + ':'+'</td> '
                        + '<td>' + ftResponsive(col.title, col.data) + '</td>'
                        + '</tr>' : '';
                    }).join('');
                    return data ? $('<table/>').append( data ) : false;
                }
            }
        });
    }
    else if(expand) {
        new $.fn.dataTable.Responsive($('#' + tb.htmlObject + 'Table'), {
            details: {
                type : 'column',
                //display: $.fn.dataTable.Responsive.display.modal(),
                renderer: function ( api, rowIdx, columns ) {
                    var data = $.map(columns, function(col, i) {
                        return (col.hidden && col.title != 'COD' && col.title != ' ' && i != 9) ? '<tr data-dt-row="'+col.rowIndex+'" data-dt-column="'+col.columnIndex+'">'
                        + '<td class="dtr-titulo">' + col.title + ':'+'</td> '
                        + '<td>' + ftResponsive(col.title, col.data) + '</td>'
                        + '</tr>' : '';
                    }).join('');
                    return data ? $('<table class="table table-condensed table-striped" />').append( data ) : false;
                }
            }
        });
        if (typeof tb._handleExpandOnClick != 'function') {
            tb._handleExpandOnClick = tb.handleExpandOnClick;
            tb.handleExpandOnClick = function(event) {
                if(event.colIdx > 1) {
                    tb._handleExpandOnClick(event);
                }
            }
        }
    }
    else {
        new $.fn.dataTable.Responsive($('#' + tb.htmlObject + 'Table'), {
            details: {
                type : 'column',
                renderer: function ( api, rowIdx, columns ) {
                    var data = $.map(columns, function(col, i) {
                        return col.hidden ? '<tr data-dt-row="'+col.rowIndex+'" data-dt-column="'+col.columnIndex+'">'
                        + '<td class="dtr-titulo">' + col.title + ':'+'</td> '
                        + '<td>' + ftResponsive(col.title, col.data) + '</td>'
                        + '</tr>' : '';
                    }).join('');
                    return data ? $('<table/>').append( data ) : false;
                }
            }
        });
    }
} 