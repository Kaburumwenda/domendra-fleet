from django.contrib import admin

from .models import Document


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ('title', 'document_type', 'vehicle', 'contact', 'expiry_date', 'created_at')
    list_filter = ('document_type',)
    search_fields = ('title', 'notes')
    raw_id_fields = ('vehicle', 'contact', 'uploaded_by')
