$(window).ready(function(){
    var modal = $('#bibtexModal').modal({
        show: false
    }).toggle();

    $('form.export-form').submit(function(){
        var form = $(this);
        $.post(form.attr('action'), form.serialize(), function(data){
            form.html(data.html);
            form.attr('action', $(data.html).attr('action'));
        }, "JSON");

        return false;
    });

    $('#commentPostForm').submit(function(){
	    var form = $(this);
	    var url = form.attr('action');
	    var data = form.serialize();
	    $.post(url,data,function(data){
	        $("#commentList").prepend($("<li>").html(data.html));
	        $('#commentText').val("");
	    }, "JSON");
	    return false;
    });

    $('#uploadForm').submit(function(){
        var form = $(this);

        $.post(form.attr('action'), form.serialize(), function(data){
            modal.modal('hide');
        });

        return false;
    })
});
