class StoryEditor
{

    goal_per_thousand_pop = null;
    eternal_love = null;
    growth_rate = null;
    city_min_growth_rate = null;
    growth_limit_0_cargos = null;
    growth_limit_1_cargos = null;
    growth_limit_2_cargos = null;
    growth_limit_3_cargos = null;
    growth_limit_4_cargos = null;

    sp_welcome = null;
    sp_growth_info = null;
    sp_custom = null;
    sp_warning = null;

    constructor() {
        this.goal_per_thousand_pop = GSController.GetSetting("goal_per_thousand_pop");
        this.eternal_love = GSController.GetSetting("eternal_love");
        this.growth_rate = GSController.GetSetting("growth_rate");
        this.city_min_growth_rate = GSController.GetSetting("city_min_growth_rate");
        this.growth_limit_0_cargos = GSController.GetSetting("growth_limit_0_cargos");
        this.growth_limit_1_cargos = GSController.GetSetting("growth_limit_1_cargos");
        this.growth_limit_2_cargos = GSController.GetSetting("growth_limit_2_cargos");
        this.growth_limit_3_cargos = GSController.GetSetting("growth_limit_3_cargos");
        this.growth_limit_4_cargos = GSController.GetSetting("growth_limit_4_cargos");
    }
}

// Main welcome page
function StoryEditor::WelcomePage(sp_welcome)
{
    GSStoryPage.NewElement(sp_welcome, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_WELCOME_1));
    GSStoryPage.NewElement(sp_welcome, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_WELCOME_2));
    GSStoryPage.NewElement(sp_welcome, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_WELCOME_3, GSCompany.GetName(GSCompany.COMPANY_FIRST)));
    GSStoryPage.NewElement(sp_welcome, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_WELCOME_4));

    if (this.eternal_love > 0) {
        GSStoryPage.NewElement(sp_welcome, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_WELCOME_5, GSText(GSText.STR_ETERNAL_LOVE_OUTSTANDING + this.eternal_love - 1)));
    }
}

// Cargo list page
function StoryEditor::GrowthInfoPage(sp_growth_info)
{
    GSStoryPage.NewElement(sp_growth_info, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_GROWTHINFO_1));
    GSStoryPage.NewElement(sp_growth_info, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_GROWTHINFO_2));
    GSStoryPage.NewElement(sp_growth_info, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_GROWTHINFO_3, this.goal_per_thousand_pop, this.growth_rate));
    GSStoryPage.NewElement(sp_growth_info, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_GROWTHINFO_4)); // TODO

    if (this.city_min_growth_rate > 0) {
        GSStoryPage.NewElement(sp_growth_info, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_GROWTHINFO_5, this.city_min_growth_rate));
    }
}

/* Create the StoryBook if it still doesn't exist. This function is
 * called only when (re)initializing all data, because the existing
 * storybook is stored by OTTD.
 */
function StoryEditor::CreateStoryBook(num_towns, init_error)
{
    // Remove any previously existant story pages
    local sb_list = GSStoryPageList(0);
    foreach (page, _ in sb_list) GSStoryPage.Remove(page);

    if (!init_error) {
        // Create welcome page
        this.sp_welcome = this.NewStoryPage(GSCompany.COMPANY_INVALID, GSText(GSText.STR_STORYBOOK_WELCOME_TITLE, SELF_MAJORVERSION, SELF_MINORVERSION));
        this.WelcomePage(this.sp_welcome);

        // Create growth info page
        this.sp_growth_info = this.NewStoryPage(GSCompany.COMPANY_INVALID, GSText(GSText.STR_STORYBOOK_GROWTHINFO_TITLE, SELF_MAJORVERSION, SELF_MINORVERSION));
        this.GrowthInfoPage(this.sp_growth_info);
        GSStoryPage.Show(this.sp_welcome);
    }

    switch (init_error) {
        case InitError.TOWN_NUMBER:
            this.sp_warning = this.NewStoryPage(GSCompany.COMPANY_INVALID, GSText(GSText.STR_STORYBOOK_WARNING_TITLE));
            GSStoryPage.NewElement(this.sp_warning, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_WARNING_TOWN_NUMBER, num_towns, SELF_MAX_TOWNS));
            GSStoryPage.Show(this.sp_warning);
            break;
        case InitError.PAX_CARGO_DIST:
            this.sp_warning = this.NewStoryPage(GSCompany.COMPANY_INVALID, GSText(GSText.STR_STORYBOOK_WARNING_TITLE));
            GSStoryPage.NewElement(this.sp_warning, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_WARNING_PASS_CARGO_DIST));
            GSStoryPage.Show(this.sp_warning);
            break;
        case InitError.INFRASTRUCTURE_SHARING:
            this.sp_warning = this.NewStoryPage(GSCompany.COMPANY_INVALID, GSText(GSText.STR_STORYBOOK_WARNING_TITLE));
            GSStoryPage.NewElement(this.sp_warning, GSStoryPage.SPET_TEXT, 0, GSText(GSText.STR_STORYBOOK_WARNING_INFRASTRUCTURE_SHARING));
            GSStoryPage.Show(this.sp_warning);
            break;
    }
}

/* Wrapper that creates a new StoryPage but disable date output. */
function StoryEditor::NewStoryPage(company, text)
{
    local value = GSStoryPage.New(company, text);
    if (value != GSStoryPage.STORY_PAGE_INVALID) {
        GSStoryPage.SetDate(value, GSDate.DATE_INVALID);
    }
    return value;
}
