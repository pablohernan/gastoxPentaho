function multicanal(cod) {
    if(parseInt(cod, 10) > 0) {
        window.parent.postMessage({data: parseInt(cod, 10), type: 'multicanal'}, "*");
    }
    else {
        $.alert({
            content: "Não foi possível executar essa ação!"
        });
    }
}

function salvarSegmentacao(cod, nome) {
    if(cod && nome) {
        $.alert({
            title: 'Informação',
            content: 'Segmentação "' + nome + '" salva com sucesso!'
        });
    }
    else {
        $.alert({
            content: "Não foi possível executar essa ação!"
        });
    }
}

function exportar(objeto, nome, tipo) {
    if(url()) {
        $("#canvasData").val('');
        $('#exportacaoData').val('');

        if(tipo == 'imagem') {
            if(isCanvasSupported()) {
                var canvas = document.getElementById('canvas');
                canvas.width = $('#' + objeto.htmlObject + 'protovis svg').width();
                canvas.height = $('#' + objeto.htmlObject + 'protovis svg').height();
                canvas.height += 33;
                var ctx = canvas.getContext('2d');
                ctx.fillStyle = '#FFFFFF';
				ctx.fillRect(0, 0, canvas.width, canvas.height);
			
				$('#' + objeto.htmlObject + 'protovis svg').wrap('<div id="svg"></div>');
				var svg = $('#svg').html().replace(/>\s+/g, '>').replace(/\s+</g, '<').replace(' xlink=', ' xmlns:xlink=').replace(/\shref=/g, ' xlink:href=');
				$('#' + objeto.htmlObject + 'protovis svg').unwrap();
                
                if(nome) {
                    ctx.drawSvg(svg, 0, 33, 0, 0);
                    ctx.fillStyle = "#1d2b36";
                    ctx.font = "italic normal bold 16px Source Sans Pro";
                    ctx.fillText(nome, 10, 20);
                }
                else {
                    ctx.drawSvg(svg, 0, 0, 0, 0);
                }
                
				var dataURL = canvas.toDataURL('image/png');
                dataURL = dataURL.replace('data:image/png;base64,', '');
				
				$('#canvasData').val(dataURL);
                $('#exportar').attr('action', pURL + 'imageCanvasServlet');
			}
		}
		else {
			var dados, metadados, resultado;
			
			if(objeto.type == 'Table') {
				dados = JSON.parse(JSON.stringify(objeto.rawData));
			}
            else {
                if(objeto.type == 'Query') {
                    metadados = JSON.parse(JSON.stringify(objeto.metadata));
                    resultado = JSON.parse(JSON.stringify(objeto.result));
                }
                else {
                    metadados = JSON.parse(JSON.stringify(objeto.chart.metadata));
                    resultado = JSON.parse(JSON.stringify(objeto.chart.resultset));
                }
                
                dados = {metadata: metadados, resultset: resultado};
            }
            
            formatar(nome, dados);
			
			$('#nmeRelatorio').val(pNomeDashboard + ' - ' + nome);
			$('#exportaPdf').val(tipo == 'pdf' ? 1 : 0);
			$('#exportacaoData').val(JSON.stringify(dados));
			$('#exportar').attr('action', pURL + 'dashboardFormatServlet');
		}
		
		$('#exportar').submit();
	}
}

function isCanvasSupported(){
    var elem = document.createElement('canvas');
	if (!!(elem.getContext && elem.getContext('2d'))) {
		return true;
	}
    else {
        $.alert({
            content: "Não é possível exportar a imagem nesse navegador!"
        });
        return false;
    }
}

function url() {
    if(pURL) {
        if(pURL.charAt(pURL.length - 1) != '/') {
            pURL += '/';
        }
        return true;
    }
    else {
        $.alert({
            content: "Configure a chave URL_SERVER_JBOSS com o endereço do WisetIt! Ex: http://localhost:8080/CCenterWeb/"
        });
        return false;
    }
}

function help(nome, dados, semimg) {
    $('#help-nome').html(nome);
    $('#help-indicators').html('');
    $('#help-inner').html('');
    
    for(var j = 0; j < dados.length; j++) {
        var li = $('<li></li>').attr('data-target', '#carousel-help').attr('data-slide-to', j);
        
        var item = dados[j];
        
        var divItem = $('<div></div>').addClass('item');
        var divImg = $('<div></div>').addClass('carrousel-image');
        var divImgInner = $('<div></div>').addClass('carrousel-image-inner');
        var img = $('<img>').attr('src', item.img).addClass('img-responsive center-block');
        if(!semimg) {
            $(img).show();
        }
        else {
             $(img).hide();
        }
        var divCaption = $('<div></div>').addClass('carousel-caption carousel-caption-help');
        var title = $('<p></p>').addClass('carousel-caption-title').html(item.title);
        var text = $('<p></p>').html(item.text);
        
        if(j === 0) {
            li.addClass('active');
            divItem.addClass('active');
        }
        
        li.appendTo('#help-indicators');
        
        img.appendTo(divImgInner);
        divImgInner.appendTo(divImg);
        divImg.appendTo(divItem);
        
        title.appendTo(divCaption);
        text.appendTo(divCaption);
        divCaption.appendTo(divItem);
        
        divItem.appendTo('#help-inner');
    }
}

function helpBtn(btn) {
    $('#' + btn.htmlObject + ' button').addClass('btn btn-help btn-sm').html('<span class="glyphicon glyphicon-question-sign"></span>');
} 

function bsInput(input, placeholder) {
    $('#render_' + input.htmlObject).addClass('form-control form-control-input input-sm').attr('placeholder',placeholder);
}

function bsSelect(sel, ro, txt, f, lim) {
    $('#' + sel.htmlObject + ' select').addClass('form-control input-sm').multiselect({
        disableIfEmpty: true,
        buttonClass: 'btn btn-default btn-sm',
        buttonWidth: '100%',
        includeSelectAllOption: !lim ? true : false,
        selectAllText: 'Selecionar Todos',
        enableFiltering: !f ? true : false,
        enableCaseInsensitiveFiltering: !f ? true : false,
        filterPlaceholder: 'Buscar',
        nonSelectedText: txt ? txt : 'Selecione',
        nSelectedText: ' Selecionados',
        allSelectedText: 'Todos Selecionados',
        maxHeight: 200
    });
    if(ro) {
        $('#' + sel.htmlObject + ' select').multiselect('disable');
    }
}

function bsSelectTitle(sel) {
    $('#' + sel.htmlObject + ' select').addClass('input-title');
}

function bsInputTitle(input) {
    $('#render_' + input.htmlObject).addClass('input-title input-title-text');
}

function bsDate(sel, opt) {
    $("#" + sel.name)
        .addClass("form-control form-control-date input-sm")
        .removeAttr("style")
        .attr('readonly','readonly')
        .attr('placeholder','Dia')
        .after('<span class="glyphicon glyphicon-calendar form-control-feedback"></span>');
        
    if(opt == 'l') {
        $("#" + sel.name).datepicker("option", {
            showButtonPanel: true,
            closeText: "Limpar",
            beforeShow: function( input ) {
                setTimeout(function() {
                    var clearButton = $(input).datepicker("widget" ).find( ".ui-datepicker-close" );
                    clearButton.unbind("click").bind("click",function(){
                        $.datepicker._clearDate(input);
                    });
                }, 1 );
            }
        });
    }
}

function bsCheckbox(sel) {
    var obj = $('#' + sel.htmlObject);
    var i = obj.find("input").toArray();
    var j = 0;
    
    obj.find("label").first().unwrap();
    
    obj.find("label").each(function(){
        $(i[j]).css('margin-top', '1px');
        $(this).unwrap().prepend(i[j]).addClass('checkbox-inline');//.unwrap();.css('line-height', '13px');
        j++;
    });
}

function bsRadio(sel, margin) {
    var obj = $('#' + sel.htmlObject);
    var i = obj.find("input").toArray();
    var j = 0;
    
    obj.find("label").each(function(){
        if(!margin) {
            $(i[j]).css('margin-top', '2px');
        }
        $(this).unwrap().prepend(i[j]).addClass('radio-inline');//.unwrap();.css('line-height', '13px');
        j++;
    });
    
    obj.find("label").first().unwrap();
}

function capitalize(text, opt) {
    if(opt == 'first') {
        return text.charAt(0).toUpperCase() + text.toLowerCase().slice(1);
    }
    else if(opt == 'firstAll') {
        return text.replace(/.+?[\.\?\!](\s|$)/g, function (txt) {
            return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
        });
    }
    var t = text.toLowerCase().replace(/([^a-záãàâéèêíïôóùûç])([a-záãàâéèêíïôóùûç])(?=[a-záãàâéèêíïôóùûç]{2})|^([a-záàãâéèêíïôóùûç])/g, function(_, g1, g2, g3) {
        return (typeof g1 === 'undefined') ? g3.toUpperCase() : g1 + g2.toUpperCase();
    });
    return t;
}

function bsButton(bt, icon, size) {
    var btsize = size ? size : 'sm';
    $('#' + bt.htmlObject + ' button').contents().wrap('<span class="btn-text"></span>');
    $('#' + bt.htmlObject + ' button').addClass("btn btn-labeled btn-default btn-"+btsize+" bold").prepend('<span class="btn-label"><i class="'+icon+'"></i></span> ');
}

function bsButtonPesquisar(bt) {
    $('#' + bt.htmlObject + ' button').addClass("btn btn-pesquisar").css('margin-left', '10px');
}

function bsButtonCancelar(bt) {
    $('#' + bt.htmlObject + ' button').addClass("btn btn-cancelar").css('margin-left', '10px');
}

function preExecucao(grafico) {
    formatChart(grafico);
    resizeChart(grafico);
    database(grafico);
}

function posDados(grafico, data) {
    if(data.resultset.length > 0) {
        zeraNulo(data);
        removeTempo(data);
        
        grafico.chartDefinition.readers = [
            {names: "series, category, value"}
        ];
        
        grafico.chartDefinition.dimensions = {
            "series" : {label: "COLUNA"},
            "value" : {label: "VALOR"}
        }
    }
} 

function posExecucao(grafico) {
    showFirstSeriesOnly(grafico);
}

function database(ob) {
    if(pDatabase && pDatabase != 'SQL' && ob.chartDefinition.dataAccessId.search('Oracle') < 0) {
        ob.chartDefinition.dataAccessId = ob.chartDefinition.dataAccessId + 'Oracle';
    }
}

function databaseSel(ob) {
    if(pDatabase && pDatabase != 'SQL' && ob.queryDefinition.dataAccessId.search('Oracle') < 0) {
        ob.queryDefinition.dataAccessId = ob.queryDefinition.dataAccessId + 'Oracle';
    }
}

function removeTempo(data) {
    data.metadata.splice(-2, 2);
    for(i = 0; i < data.resultset.length; i++) {
        var x = data.resultset[i];
        x.splice(-2, 2);
    }
}

function dhms(s) {            
    var dd = Math.floor(s / 86400);
    if(dd > 0) {
        s -= dd * 86400;
    }
    var hh = Math.floor(s / 3600);
    s -= hh * 3600;
    var mm = Math.floor(s / 60);
    s -= mm * 60;
    var ss = s;
    return (dd ? dd + "d" : "") + /*(hh < 10 ? "0" : "") + */hh + "h" + /*(mm < 10 ? "0" : "") + */mm + "m"/* + (ss < 10 ? "0" : "") + ss + "s"*/;
}

function formatBar(tb) {
    $('#' + tb.htmlObject + 'Table td').find('div').each(function(){
        $(this).find('span').insertBefore($(this).find('svg'));
    });
}

function invertTable(tb) {
    var th = $('#' + tb.htmlObject + 'Table th');
    var td = $('#' + tb.htmlObject + 'Table td');
    for(var i = 0; i < th.length; i++) {
        $('#' + tb.htmlObject + 'Table').append('<tr>' + th[i].outerHTML + td[i].outerHTML + '</tr>');
    }
    $('#' + tb.htmlObject + 'Table thead').remove();
    $('#' + tb.htmlObject + 'Table tr:first').remove();
}

function drawTable(tb, v) {
    $('#' + tb.htmlObject + 'Table').find('th').each(function(){
        $(this).removeAttr('style');
    });
    if(v == 1) {
        $('#' + tb.htmlObject + 'Table').find('tr').each(function(){
            $(this).addClass('pointer');
        });
    }
    if(v == 4) {
        $('#' + tb.htmlObject + 'Table tr:gt(0)').addClass('success');
    }
}

function zeraNulo(data) {
    var rs = data.resultset;
    var i, j;
    for(i = 0; i < rs.length; i++) {
        var x = rs[i];
        
        for(j = 0; j < x.length; j++) {
            x[j];
            if( x[j] == null ) {
                x[j] = 0;
            }
        }
    }
}

function refreshTable(tabela) {
    var tb = tabela;
    
    if (!tabela.resizeHandlerAttached) {
        
        var debouncedResize = _.debounce(function() {
            tb.update();
        }, 200);

        $(window).resize(function() {
            debouncedResize(); 
        });
        
        tabela.resizeHandlerAttached = true;
    }
}

function resizeChart(grafico) {
    
    var myself = grafico;
    
    myself.chartDefinition.width = myself.placeholder().width();

    if (!grafico.resizeHandlerAttached) {
        
        var debouncedResize = _.debounce(function() {
            myself.placeholder().children().css('visibility','visible');
            myself.chartDefinition.width = myself.placeholder().width();
            if(myself.dadosModificados) {
                myself.render( myself.dadosModificados );
            }
            else {
                myself.render( myself.query.lastResults() );
            }
        }, 200);

        $(window).resize(function() {
            if ( myself.chartDefinition.width != myself.placeholder().width()) {
                myself.placeholder().children().css('visibility','hidden');
                debouncedResize();
            }    
        });
        
        grafico.resizeHandlerAttached = true;
    }
}

function legend(grafico) {
    grafico.chartDefinition.legend = {
        scenes: {
            item : {
                execute: function() {
                    if(!pvc.data.Data.toggleVisible(this.datums())) return;
                    
                    this.clearCachedState();
                    
                    if(this.isOn()) {
                        var me = this;
                        
                        this.root.childNodes.forEach(function(group) {
                            if(group.clickMode === 'togglevisible') {
                                group.childNodes.forEach(function(item) {
                                    
                                    if(item !== me && item.executable() && item.isOn()) {
                                        pvc.data.Data.setVisible(item.datums(), false);
                                    }
                                });
                            }
                        });
                    }
                    
                    this.chart().render(true, true, false);
                }
            }
        }
    };
}

function showFirstSeriesOnly(grafico) {
    if(grafico.chart.data != null) {
        var firstSeries = grafico.chart.data.dimensions('series').min();
        var hideDatums  = grafico.chart.data.datums(null, {
            where: function(d) { 
                return d.atoms.series !== firstSeries; 
            }
        });
        
        pvc.data.Data.setVisible(hideDatums, false);
        
        grafico.chart.render(true, true, false);
    }
} 

function numericBR(valor, decimais){
    if(!valor) valor = 0;
    valor=parseFloat(valor).toFixed(decimais); 
    valor=valor.replace(/(\d{1,3})\.(\d{1,2})\b\b/, "$1,$2");
    valor=valor.replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1.");
    return valor;
}

function formatChart(grafico) {
    grafico.chartDefinition.format = {
        number: {
            style: {
                decimal: ",",
                group:   "."
            }
        },
        percent: {
            style: {
                decimal: ",",
                group:   "."
            }
        },
        date: {
            mask: '%d/%m/%Y'
        }
    };
}

function salvarImg(id) {
    var canvas = document.getElementById('canvas');
    $("#" + id + "protovis svg").wrap('<div id="svg"></div>');
    var svg = $("#svg").html().replace(/>\s+/g, ">").replace(/\s+</g, "<").replace(" xlink=", " xmlns:xlink=").replace(/\shref=/g, " xlink:href=");
    $("#" + id + "protovis svg").unwrap();
    canvg(canvas, svg, { ignoreMouse: true, ignoreAnimation: true });
    var dataURL = canvas.toDataURL("image/png");
    dataURL = dataURL.replace('data:image/png;base64,', '');
    
    $("#canvasData").val(dataURL);
    $("#download").submit();
}

function calculaTotal(data) {
    var rs = data.resultset;
    
    if(rs.length > 0) {
        var total = [];
        var i, j, x, y;
        var rm = data.metadata;
        
        for(i = 0; i < rm.length; i++) {
            if( i === 0 ) {
                total.push('000');
            }
            else if( i === 1 ) {
                total.push("TOTAL");
            }
            else if( i === 2 ) {
                total.push("TOTAL");
            }
            else {
                var type = rm[i].colType;
                if( type === "String" ) {
                    total.push(null);
                }
                else {
                    total.push(0);
                }
            }
        }
        
        for(i = 0; i < rs.length; i++) {
            x = rs[i];
            
            for(j = 4; j < x.length; j++) {
                y = x[j];
                if( typeof(y) != 'string' && y != null ) {
                    total[j] += y;
                }
            }
        }
        total[7] = total[6] / total[5] * 100;
        total[9] = total[8] / total[5] * 100;
        total[11] = total[10] / total[5] * 100;
        total[13] = total[12] / total[5] * 100;
        //total[12] = '...';
        //total[13] = '...';
        //total[9] = total[5] - (total[6] + total[7] + total[8]);
        //total[10] = '';
        
        rs.unshift(total);
    }
}

function ordenaComparativo(d) {
    var rs = d.resultset;
    var a = [], b =[];
    
    for(var i = 0; i < rs.length; i++) {
        var x = rs[i];
        if(x[2] == x[3]) {
            a.push(x);
        }
        else {
            b.push(x);
        }
    }
    d.resultset = a.concat(b);
}

function screen() {
    if($('body').outerWidth(true) < 768) return 'xs';
    
    if($('body').outerWidth(true) < 992) return 'sm';
    
    if($('body').outerWidth(true) < 1200) return 'md';
    
    return 'lg'
}

function reDraw(tb) {
    var t = $('#' + tb.htmlObject + 'Table').dataTable();
    t.fnDraw();
}