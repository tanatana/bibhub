$(window).ready(function(){
    $('#bibtexModal').modal({
        show: false
    }).toggle();

    $('form.export-form').submit(function(){
        var form = $(this);
        var url = form.attr('action');
        var data = form.serialize();
        $.post(url, data, function(data){
            form.html(data.html);
            form.attr('action', $(data.html).attr('action'));
        }, "JSON");

        return false;
    });

});
